variable "aws-region" {
  type = string
}

variable "environment" {
  type = string
}

variable "alb_settings" {
  type = list(any)
  default = [
    {
      resource_unique_id    = "frontend"
      alb-create            = true
      alb-type              = "internet-facing"
      load_balancer_type    = "application"
      alb_port              = 80
      protocol              = "HTTP"
      health_check-enabled  = true
      health_check-interval = 30
      subnet_tier           = "Public"
      sg_name               = "frontend-alb-sg"
    },
    {
      resource_unique_id    = "backend"
      alb-create            = true
      alb-type              = "internal"
      load_balancer_type    = "application"
      alb_port              = 80
      protocol              = "HTTP"
      health_check-enabled  = true
      health_check-interval = 30
      subnet_tier           = "Private"
      sg_name               = "backendend-alb-sg"
    }
  ]
}

variable "ecs_settings" {
  type = list(any)
  default = [
    {
      resource_unique_id = "frontend"
      ecs_cluster-create = true
      subnet_tier        = "Public"
      sg_name            = "frontend-ecs-sg"
      assign_public_ip   = true
      container_port     = 80
    },
    {
      resource_unique_id = "backend"
      ecs_cluster-create = true
      subnet_tier        = "Private"
      sg_name            = "backend-ecs-sg"
      assign_public_ip   = false
      container_port     = 80
    }
  ]
}

variable "sg_settings" {
  type = list(any)
  default = [
    {
      service = "frontendecs"
      sg_name = "frontend-ecs-sg"
    },
    {
      service = "frontendalb"
      sg_name = "frontend-alb-sg"
    },
    {
      service = "backendecs"
      sg_name = "backend-ecs-sg"
    },
    {
      service = "backendalb"
      sg_name = "backend-alb-sg"
    }
  ]
}

variable "sg_rule_settings" {
  type = list(any)
  default = [
    {
      sg_name        = "backend-alb-sg"
      rule_type      = "ingress"
      rule_name      = "rule1"
      source_sg_name = "frontend-ecs-sg"
    },
    {
      sg_name        = "backend-ecs-sg"
      rule_type      = "ingress"
      rule_name      = "rule1"
      source_sg_name = "backend-alb-sg"
    },
    {
      sg_name        = "frontend-ecs-sg"
      rule_type      = "ingress"
      rule_name      = "rule1"
      source_sg_name = "frontend-alb-sg"
    },
    {
      sg_name        = "frontend-alb-sg"
      rule_type      = "ingress"
      rule_name      = "rule1"
      cidr_blocks 	 = ["0.0.0.0/0"]
    }

  ]
}

variable "vpc_id" {
  type    = string
  default = "vpc-01234"
}

variable "tags" {
  type    = map(string)
  default = {}
}

