// Roles
# Role que o ECS usa para subir o container (baixar imagem, logs)
resource "aws_iam_role" "ecs_exec_role" {
  name = "hospital-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Anexa a política padrão da AWS para execução de tarefas
resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Role que a sua API Kotlin usa (para ler o SSM Parameter Store de graça)
resource "aws_iam_role" "ecs_task_role" {
  name = "hospital-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Permissão para sua API ler os parâmetros do SSM
resource "aws_iam_role_policy" "ssm_read" {
  name = "ssm-read-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "ssm:GetParameter", "ssm:GetParametersByPath"]
      Resource = "*" # Em produção, limite ao path da sua API
    }]
  })
}

// ECS
resource "aws_ecs_cluster" "main" {
  name = "hospital-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "hospital-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU (Free Tier)
  memory                   = "512" # 0.5 GB (Free Tier)
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "hospital-container"
    image = "197476564977.dkr.ecr.us-east-1.amazonaws.com/hospital-api:latest" # Sua imagem no ECR
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]

    environment = [
      {
        name  = "DB_HOST"
        value = replace(aws_db_instance.mysql_free.endpoint, ":3306", "")
      }
    ]

    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]

    # Configuração de logs para você debugar no CloudWatch
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/hospital-api"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}
# Cria o grupo de logs no CloudWatch
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/hospital-api"
  retention_in_days = 7
}

resource "aws_ecs_service" "main" {
  name            = "hospital-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Necessário para baixar imagem sem NAT Gateway (Free Tier!)
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "hospital-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.nlb_listener]
}

// ECS + NLB
resource "aws_ecs_service" "main" {
  name            = "hospital-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Necessário para baixar imagem sem NAT Gateway (Free Tier!)
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "hospital-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.nlb_listener]
}