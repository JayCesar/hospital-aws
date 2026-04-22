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

# O "Alvo" (Seus containers ECS). ou seja, para on o Listener envia
resource "aws_apigatewayv2_api" "http_api" {
  name          = "hospital-gateway"
  protocol_type = "HTTP"
}

# Integração com o NLB via VPC Link
# resource "aws_apigatewayv2_integration" "ecs_integration" {
#   api_id           = aws_apigatewayv2_api.http_api.id
#   integration_type = "HTTP_PROXY"
#
#   # Como o IP do ECS muda, o ideal aqui para custo zero e sem erro
#   # é usar o Cloud Map ou apontar para o IP público da Task (mais simples para teste)
#   integration_uri  = "http://${aws_ecs_service.main.network_configuration[0].assign_public_ip}:8080"
#
#   # Sem o NLB, não precisamos de VPC_LINK para testes rápidos
#   connection_type = "INTERNET"
#   payload_format_version = "1.0"
# }

# Define que qualquer requisição (ANY /) vai para o ECS
# resource "aws_apigatewayv2_route" "default_route" {
#   api_id    = aws_apigatewayv2_api.http_api.id
#   route_key = "ANY /{proxy+}"
#   target    = "integrations/${aws_apigatewayv2_integration.ecs_integration.id}"
# }

# Cria o endpoint final (URL pública)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

data "aws_availability_zones" "available" {}