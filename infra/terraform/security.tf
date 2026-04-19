resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "rds-db-password-v2"
}


resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id     = aws_secretsmanager_secret.db_password.id

  # Aqui montamos o JSON completo que o seu Driver da AWS vai ler
  secret_string = jsonencode({
    username = "admin"                                # Usuário que você definiu no RDS
    password = random_password.password.result        # A senha aleatória gerada acima
    host     = aws_db_instance.mysql_free.address        # O endpoint que o RDS vai gerar
    port     = 3306
    engine   = "mysql"
  })
}