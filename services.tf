terraform {
  backend "s3" {
  }
}

provider "aws" {
  region  = var.aws-region
  profile = "default"
}

locals {

  alb_settings = [for key in var.alb_settings :
    {
      resource_unique_id    = key.resource_unique_id
      alb-create            = key.alb-create
      alb-type              = key.alb-type
      load_balancer_type    = key.load_balancer_type
      security_groups       = [aws_security_group.this[key.sg_name].id]
      alb-subnet_ids        = concat([element(data.aws_subnets.this[key.subnet_tier].ids, 0)], [element(data.aws_subnets.this[key.subnet_tier].ids, 1)])
      alb_port              = try(key.alb_port, null)
      protocol              = try(key.protocol, null)
      health_check-enabled  = try(key.health_check-enabled, null)
      health_check-interval = try(key.health_check-interval, null)
      subnet_tier           = key.subnet_tier
    } if key.alb-create == true
  ]

  ecs_settings = [for key in var.ecs_settings :
    {
      ecs_cluster-create = key.ecs_cluster-create
      resource_unique_id = key.resource_unique_id
      subnet_tier        = key.subnet_tier
      ecs_service-network_configuration = {
        subnets          = concat([element(data.aws_subnets.this[key.subnet_tier].ids, 0)], [element(data.aws_subnets.this[key.subnet_tier].ids, 1)])
        security_groups  = [aws_security_group.this[key.sg_name].id]
        assign_public_ip = try(key.assign_public_ip, false)
      }
      load_balancer-target_groups = {
        container_name   = "${key.resource_unique_id}-container"
        target_group_arn = lookup(local.target_group_arns, "${key.resource_unique_id}-alb")
        container_port   = try(key.container_port, 80)
      }
      container_definitions = jsonencode(file("${path.module}/containerdefs/${key.resource_unique_id}service.json"))
    } if key.ecs_cluster-create == true
  ]

  alb_settings_map        = { for key in local.alb_settings : "${key.resource_unique_id}-alb" => key }
  ecs_service_settings    = { for key in local.ecs_settings : "${key.resource_unique_id}-service" => key }
  service_subnet_settings = { for key in local.ecs_settings : key.subnet_tier => key }

  sg_settings      = { for key in var.sg_settings : key.sg_name => key }
  sg_rule_settings = { for key in var.sg_rule_settings : "${key.sg_name}-${rule_name}" => key }

  target_group_arns = merge({
    for k, v in module.lb : k => v.target_group_arn
  })

}

data "aws_caller_identity" "this" {}

data "aws_subnets" "this" {
  for_each = local.service_subnet_settings

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Tier = key.subnet_tier
  }

}

module "services" {
  source = "./modules/ecs"

  for_each = local.ecs_service_settings

  ecs_cluster-create                            = lookup(each.value, "ecs_cluster-create")
  region                                        = var.aws-region
  environment                                   = var.environment
  ecs_service-create                            = lookup(each.value, "ecs_cluster-create") == true ? true : false
  resource_unique_id                            = lookup(each.value, "resource_unique_id")
  ecs_service-iam_role                          = lookup(each.value, "ecs_service-iam_role_arn", null)
  ecs_service-desired_count                     = lookup(each.value, "ecs_service-desired_count", 1)
  ecs_service-health_check_grace_period_seconds = lookup(each.value, "ecs_service-health_check_grace_period_seconds", 30)
  ecs_service-wait_for_steady_state             = lookup(each.value, "ecs_service-wait_for_steady_state", true)
  ecs_service-force_new_deployment              = lookup(each.value, "ecs_service-force_new_deployment", false)
  ecs_service-launch_type                       = lookup(each.value, "ecs_service-launch_type", "FARGATE")
  ecs_service-network_configuration             = lookup(each.value, "ecs_service-network_configuration")
  ecs_service-platform_version                  = lookup(each.value, "ecs_service-launch_type", "FARGATE") == "FARGATE" ? lookup(each.value, "ecs_service-platform_version", null) != null ? lookup(each.value, "ecs_service-platform_version") : null : null
  load_balancer-target_groups                   = lookup(each.value, "load_balancer-target_groups")
  task_definition-create                        = lookup(each.value, "ecs_cluster-create") == true ? true : false
  launch_type_compatibility                     = lookup(each.value, "ecs_service-launch_type", "FARGATE")
  container_definitions                         = lookup(each.value, "container_definitions")
  cpu                                           = lookup(each.value, "cpu", 1024)
  memory                                        = lookup(each.value, "memory", 2048)
  task_role_arn                                 = lookup(each.value, "task_role_name", null) != null ? "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${lookup(each.value, "task_role_name")}" : null
  execution_role_arn                            = lookup(each.value, "execution_role_name", null) != null ? "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${lookup(each.value, "execution_role_name")}" : null

  tags = var.tags

  depends_on = [
    module.lb,
    aws_security_group.this,
    aws_security_group_rule.this,
    data.aws_subnets.this
  ]

}

module "lb" {
  source = "./modules/alb"

  for_each = local.ecs_alb_settings

  region                 = var.aws-region
  environment            = var.environment
  alb-vpc_id             = var.vpc_id
  alb-create             = lookup(each.value, "alb-create")
  alb-type               = lookup(each.value, "alb-type")
  load_balancer_type     = lookup(each.value, "load_balancer_type", "application")
  alb-security_group_ids = lookup(each.value, "load_balancer_type", "application") == "application" ? lookup(each.value, "security_groups", null) : null
  alb-subnet_ids         = lookup(each.value, "alb-subnet_ids")
  alb_port               = lookup(each.value, "alb_port", 80)
  protocol               = lookup(each.value, "alb_protocol", "HTTP")
  health_check-enabled   = lookup(each.value, "health_check-enabled", true)
  health_check-interval  = lookup(each.value, "health_check-interval", 30)

  tags = var.tags

  depends_on = [
    aws_security_group.this,
    aws_security_group_rule.this,
    data.aws_subnets.this
  ]

}

resource "aws_security_group" "this" {

  for_each = local.sg_settings

  name   = lookup(each.value, "sg_name")
  vpc_id = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "this" {
  for_each = local.sg_rule_settings

  type                     = each.value.rule_type
  from_port                = lookup(each.value, from_port, 80)
  to_port                  = lookup(each.value, to_port, 80)
  protocol                 = lookup(each.value, to_port, "tcp")
  source_security_group_id = lookup(each.value, "source_sg_name", null) != null ? aws_security_group.this[each.value.source_sg_name].id : null
  security_group_id        = aws_security_group.this[each.value.sg_name].id
  cidr_blocks              = lookup(each.value, "source_sg_name", null) != null ? lookup(each.value, "cidr_blocks") : null

}