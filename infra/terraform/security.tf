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

# Security Group para o VPC Link / NLB
resource "aws_security_group" "nlb_sg" {
  name   = "hospital-nlb-sg"
  vpc_id = aws_vpc.main.id

  # Entrada: API Gateway enviando tráfego
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # O VPC Link gerencia a segurança real
  }

  # Saída: Liberado para os containers
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para o ECS (Sua API Kotlin)
resource "aws_security_group" "ecs_sg" {
  name   = "hospital-ecs-sg"
  vpc_id = aws_vpc.main.id

  # Entrada: Só aceita tráfego vindo do NLB
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb_sg.id]
  }

  # Saída: Para falar com o RDS e baixar dependências
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}