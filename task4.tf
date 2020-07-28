provider "aws" {
  profile = "myprofile"
  region = "ap-south-1"
}

// create vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  enable_dns_hostnames = true

  tags = {
    Name = "tfvpc"
  }
}

// create subnet 1 in AZ 1a (Public Subnet)
resource "aws_subnet" "sub-1a" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "sub-1a"
  }
}

// create subnet 2 in AZ 1b ((Private Subnet)
resource "aws_subnet" "sub-1b" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "sub-1b"
  }
}

// create IG
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "tfGW"
  }
}

// Create EIP
resource "aws_eip" "nat" {
  vpc              = true
}

// NAT Gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.sub-1a.id

  tags = {
    Name = "NAT GW - 1a"
  }
}

// create RT updated with above IG for public subnet
resource "aws_route_table" "rt-a" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "tfRT-a"
  }
}

// create RT updated with above NAT Gateway
resource "aws_route_table" "rt-b" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "tfRT-b"
  }
}

// subnet association in RT for public subnet
resource "aws_route_table_association" "sub-a" {
  subnet_id      = aws_subnet.sub-1a.id
  route_table_id = aws_route_table.rt-a.id
}

// subnet association in RT for private subnet
resource "aws_route_table_association" "sub-b" {
  subnet_id      = aws_subnet.sub-1b.id
  route_table_id = aws_route_table.rt-b.id
}

// create security group for wordpress
resource "aws_security_group" "mywpsg" {
  depends_on = [ aws_vpc.myvpc ]
  name        = "wordpress_sg"
  description = "Allow TLS inbound and outboud traffics"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress"
  }
}

// use ubuntu 18.04 for wordpress instance
resource "aws_instance" "mywpinstance" {
  depends_on = [ aws_subnet.sub-1a, aws_security_group.mywpsg ]
  ami = "ami-02d55cb47e83a99a0"
  instance_type = "t2.micro"
  key_name = "clios"
  subnet_id = aws_subnet.sub-1a.id
 vpc_security_group_ids = [ "${aws_security_group.mywpsg.id}" ]
  tags = {
    Name = "wordpress"
  }
}

// create security group for mysql
resource "aws_security_group" "mysqlsg" {
  depends_on = [ aws_vpc.myvpc ]
  name        = "mysql_sg"
  description = "Allow TLS inbound and outboud traffics"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [ "${aws_security_group.mywpsg.id}" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql"
  }
}

// launch manually pre-configured mysql instance, use ubuntu 18.04
resource "aws_instance" "mysqlinstance" {
  depends_on = [ aws_subnet.sub-1b, aws_security_group.mysqlsg ]
  ami = "ami-02d55cb47e83a99a0"
  instance_type = "t2.micro"
  key_name = "clios"
  subnet_id = aws_subnet.sub-1b.id
  vpc_security_group_ids = [ "${aws_security_group.mysqlsg.id}" ]
  tags = {
    Name = "mysql"
  }
}


// Setup wordpress in ec2
# sudo su -
# apt-get update
# apt-get upgrade -y
# apt-get install apache2 -y
# apt-get install php7.2 php7.2-curl php7.2-mysql php7.2-mbstring php7.2-dom php7.2-gd -y
# apt-get install libapache2-mod-php7.2 -y
# apt-get install mysql-client -y
# cd /var/www/html
# rm -rf *
# wget https://wordpress.org/latest.tar.gz
# tar -xzvf latest.tar.gz
# mv wordpress/* ./
# rm -r wordpress latest.tar.gz
# chown -R www-data:www-data /var/www/html

// Setup mysql
# apt-get update
# apt-get upgrade -y
# apt-get install mysql-server mysql-client -y

# mysql_secure_installation
# - Enable Validate Password Plugin? No
# - Change the password for root? No
# - Remove anonymous users? Yes
# - Disallow root login remotely? Yes
# - Remove test database and access to it? Yes
# - Reload privilege table now? Yes

# nano /etc/mysql/mysql.conf.d/mysqld.cnf
#   - bind-address = private_ip
# service mysql restart

# mysql -uroot -p
# mysql> CREATE DATABASE wordpress;
# mysql> CREATE USER ‘wordpressUser‘@’wordpress_private_ip‘ IDENTIFIED BY ‘qawsedrf123‘;
# mysql> GRANT ALL PRIVILEGES ON wordpress.* TO ‘wordpressUser‘@’wordpress_private_ip‘;
# mysql> FLUSH PRIVILEGES;
# mysql> exit;