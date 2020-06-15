provider "aws" {
	region = "ap-south-1"
	profile = "myprofile"
}

// create key pair

variable "KEY_NAME" {
	type = string
	default = "mykey"
}

resource "aws_key_pair" "key_pair" {
  	key_name   = var.KEY_NAME
  	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD86/RVuG+okir8pRDUCSHalNTQ+/BV1VVKyGU6CHtXEOkzbJXsnJ+IYS6I2rZ/tazaqB8rF8y6/cblXtCxQuhpa/XCh4tVqDo4gY9jTDiTvwTKpA1rEZdHMqOLDLag3O1d8PgHkMN35vbb2/zcxq/3p9pvNRUc7tQXagVC5m7lsSvASZiNrRryB/ZMRaVDzutXF1iNLYwG8lvT1nWgyE4tpZxLUCePBDgZtHO4+sQ55S432NAO1BWgxcY6VkA8Nv6uqwL1+gOcR6LR294yLqsN4PaafPXQaFLewm4rrljpqq3OWbl8vyelO97wup1aoQY5ybP0TV1pOwGHjvvaaQ1 garg@DESKTOP-NP73SNP"
}

// create security group

resource "aws_security_group" "mysg" {
  name        = "security_group1"
  description = "Allow TLS inbound and outboud traffics"

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
    Name = "terraform_sg"
  }
}

// create ec2 instance

variable "AMI" {
	type = string
	default = "ami-0447a12f28fddb066"
}

resource "aws_instance" "myinstance" {
	depends_on = [ aws_key_pair.key_pair , aws_security_group.mysg ]
	ami = var.AMI
	instance_type = "t2.micro"
	key_name = var.KEY_NAME
	security_groups = [ "${aws_security_group.mysg.name}" ]
	tags = {
		Name = "terraformos"
	}

	connection {
    		type     = "ssh"
    		user     = "ec2-user"
    		private_key = file("C:/Users/GARG/.ssh/mykey.pem")
   	 	host     = aws_instance.myinstance.public_ip
  	}

	provisioner "remote-exec" {
		inline = [
			"sudo yum install git httpd php -y",
			"sudo systemctl restart httpd",
			"sudo systemctl enable httpd"
		]
	}
}

// create ebs volume

resource "aws_ebs_volume" "ebs_new" {
	availability_zone = aws_instance.myinstance.availability_zone
	size = 1
	tags = {
		Name = "ebs1"
	}
}

// attach ebs volume to ec2 instance, download code from github

resource "aws_volume_attachment" "ebs_att" {
	depends_on = [aws_instance.myinstance , aws_ebs_volume.ebs_new]
  	device_name = "/dev/sdh"
  	volume_id   = "${aws_ebs_volume.ebs_new.id}"
  	instance_id = "${aws_instance.myinstance.id}"
	force_detach = true

	connection {
    		type     = "ssh"
    		user     = "ec2-user"
    		private_key = file("C:/Users/GARG/.ssh/mykey.pem")
   	 	  host     = aws_instance.myinstance.public_ip
  	}

	provisioner "remote-exec" {
		inline = [
			"sudo mkfs.ext4 /dev/xvdh",
			"sudo mount /dev/xvdh /var/www/html",
			"sudo rm -rf /var/www/html/*",
			"sudo git clone https://github.com/vikasgargvi/WebTestRepo.git /var/www/html/"
		]
	}	
}

// create bucket

resource "aws_s3_bucket" "image_bucket" {
	bucket = "tf-web-test-bucket"
	acl = "public-read"
	versioning {
		enabled=true
	}
}

// upload image to s3 bucket

resource "null_resource" "download_image_from_github" {
	provisioner "local-exec" {
		command = "git clone https://github.com/vikasgargvi/Web-Test-Image.git web-image"
	}

	provisioner "local-exec" {
		when = destroy
		command     =   "echo Y | rmdir /s web-image"
	}
}

resource "aws_s3_bucket_object" "image_upload" {
	depends_on = [ aws_s3_bucket.image_bucket, null_resource.download_image_from_github ]
	
	bucket = aws_s3_bucket.image_bucket.bucket
  	key    = "myimage"
  	source = "web-image/vikas.jpeg"
	acl = "public-read"

	tags = {
  		Name = "Image bucket"
    	Environment = "Dev"
  	}
}

// create S3 CloudFront Distribution

variable "s3_origin_id" {
	type = string
	default = "mys3origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

	depends_on = [ aws_s3_bucket.image_bucket ]

	origin {
		origin_id = var.s3_origin_id
		domain_name = "${aws_s3_bucket.image_bucket.bucket_domain_name}"
	}
	
	enabled = true

	default_cache_behavior {
    		allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    		cached_methods   = ["GET", "HEAD"]
    		target_origin_id = var.s3_origin_id
		viewer_protocol_policy = "redirect-to-https"

    		forwarded_values {
	      		query_string = false

	      		cookies {
        			forward = "none"
            }
    		}
	}

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}

	viewer_certificate {
		cloudfront_default_certificate = true
	}

	connection {
    		type     = "ssh"
    		user     = "ec2-user"
    		private_key = file("C:/Users/GARG/.ssh/mykey.pem")
   	 	host     = aws_instance.myinstance.public_ip
  	}

	provisioner "remote-exec" {
        	inline  = [
            	"sudo su << EOF",
           		"echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.image_upload.key}' height='200' width='200'>\" >> /var/www/html/index.html",
            	"EOF"
        	]
    	}
}

resource "null_resource" "launch_website" {
	depends_on = [ aws_cloudfront_distribution.s3_distribution ]

	provisioner "local-exec" {
		command = "start chrome ${aws_instance.myinstance.public_ip}"
	}
}