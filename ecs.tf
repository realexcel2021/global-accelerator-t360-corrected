##################################################
# build docker image


resource "aws_ecr_repository" "foo" {
  name                 = "${random_pet.this.id}-load_testing-image"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "build_dotnet_app-image" {
  provisioner "local-exec" {
    command = <<EOT
      docker build -t load_testing .
    EOT
    working_dir = "./src/Locust"
    interpreter = ["PowerShell", "-Command"]
  }
  
}


# loging to ecr

resource "null_resource" "login-ecr" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
    EOT
  }
  
}

resource "null_resource" "tag_image" {
  provisioner "local-exec" {
    command = <<EOT
      docker tag load_testing:latest ${aws_ecr_repository.foo.repository_url}:latest
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [ null_resource.build_dotnet_app-image ]
}

resource "null_resource" "push_image" {
  provisioner "local-exec" {
    command = <<EOT
      docker push ${aws_ecr_repository.foo.repository_url}:latest
    EOT
    interpreter = ["PowerShell", "-Command"]
  
  }
  depends_on = [ null_resource.tag_image ]
  
}


module "ecs_cluster" {

  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.0"
  depends_on = [ aws_ecr_repository.foo ]

  cluster_name = "Config360-${random_pet.this.id}-load_testing"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"
  name = "load_testing-svc"
  cluster_arn = module.ecs_cluster.arn


  load_balancer = {
    service = {
      target_group_arn = module.alb_load.target_groups["ex-ip"].arn
      container_name   = "load_testing"
      container_port   = 8090
    }
  }

  subnet_ids                         = module.vpc.private_subnets
  desired_count                      = 1
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0


  security_group_rules = {
    alb_ingress_8090 = {
      type                     = "ingress"
      from_port                = 8090
      to_port                  = 8090
      protocol                 = "tcp"
      description              = "Service port"
      cidr_blocks              = ["0.0.0.0/0"]
    }
    alb_ingress_8090_sg = {
      type                     = "ingress"
      from_port                = 8090
      to_port                  = 8090
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = "${module.alb.security_group_id}"
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  container_definitions = {
    
    load_testing = {
      requires_compatibilities = ["FARGATE"]
      network_mode             = "awsvpc"
      cpu       = 1024
      memory    = 2048
      essential = true
      image     = "${aws_ecr_repository.foo.repository_url}"
      port_mappings = [
        {
          name          = "app-port"
          containerPort = 8090
          protocol      = "tcp"
        }
      ]

      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          # Name                    = "awslogs-group"
          # region                  = "us-east-1"
          awslogs-group = "load_testing-${random_pet.this.id}-task-logs"
          awslogs-region = "us-east-1"
          awslogs-stream-prefix = "load_testing"
          awslogs-create-group = "true"
        #   log-driver-buffer-limit = "2097152"
        }
      }
    }
  }
}


resource "aws_cloudwatch_log_group" "rabbitmq" {
  name = "load_testing-${random_pet.this.id}-task-logs"
  retention_in_days = 1
}
