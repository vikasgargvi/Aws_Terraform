// RDS MySQL Engine
resource "aws_db_instance" "default" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  identifier           = "testdb1"
  username             = "vikas"
  password             = "password"
  allocated_storage    = 20
  storage_type         = "gp2"
  publicly_accessible  = true
  name                 = "mydb1"
  parameter_group_name = "default.mysql5.7"

  skip_final_snapshot  = true
  # option_group_name    = "default.mysql5.7"
  tags = {
    Name = "tfdb"
  }
}

output "dns" {
  value = aws_db_instance.default.address
}