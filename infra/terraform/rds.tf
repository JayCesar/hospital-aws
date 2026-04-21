resource "aws_db_subnet_group" "rds_subnets" {
  name       = "main-subnet-group"
  subnet_ids = aws_subnet.subnets[*].id
}

resource "aws_db_instance" "mysql_free" {
  allocated_storage = 20
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  identifier        = "rds-mysql-free"
  db_name           = "estudo_db"
  username          = "admin"
  password          = random_password.password.result

  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true
  skip_final_snapshot = true
}

