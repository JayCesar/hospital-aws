resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "vpc-rds-estudo" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

// Cria a vpcLink
resource "aws_apigatewayv2_vpc_link" "vpclink" {
  name               = "hospital-vpc-link"
  security_group_ids = [aws_security_group.nlb_sg.id] # SG para o link
  subnet_ids         = aws_subnet.subnets[*].id
}

// Cria o NLB
resource "aws_lb" "nlb" {
  name               = "hospital-nlb"
  internal           = true # Mantém interno para ser acessado apenas pelo API Gateway
  load_balancer_type = "network"
  subnets            = aws_subnet.subnets[*].id
}

// Cria o listener do NLB
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# O "Alvo" (Seus containers ECS). ou seja, para on o Listener envia
resource "aws_lb_target_group" "ecs_tg" {
  name        = "hospital-ecs-tg"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Fargate exige target_type ip

  health_check {
    protocol = "TCP"
    port     = "8080"
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "hospital-gateway"
  protocol_type = "HTTP"
}

# Integração com o NLB via VPC Link
resource "aws_apigatewayv2_integration" "ecs_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.nlb_listener.arn

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.vpclink.id
  payload_format_version = "1.0"
}

# Define que qualquer requisição (ANY /) vai para o ECS
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ecs_integration.id}"
}

# Cria o endpoint final (URL pública)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

data "aws_availability_zones" "available" {}