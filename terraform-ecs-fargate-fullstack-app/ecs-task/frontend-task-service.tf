
# Application Load Balancer
resource "aws_lb" "front-elb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.sg.id]
  subnets            = [data.aws_subnet.public1.id, data.aws_subnet.public2.id]
}

# Target Group
resource "aws_lb_target_group" "front-tg" {
  name        = "frontend-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"
}

# Listener for ALB
resource "aws_lb_listener" "front_listener" {
  load_balancer_arn = aws_lb.front-elb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front-tg.arn
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "front_task" {
  family                   = "front-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "421954350274.dkr.ecr.us-east-1.amazonaws.com/frontend:latest"   # Replace you frontend image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"

}
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "front_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.front_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [data.aws_subnet.private1.id, data.aws_subnet.private2.id]
    security_groups = [data.aws_security_group.sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.front-tg.arn
    container_name   = "frontend"
    container_port   = 80
  }
}
