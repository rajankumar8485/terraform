locals {

 resource_name_pattern = replace(join("-", ["${var.region}","${var.environment}","${var.resource_unique_id}"]), "/_*||", "")
 network_mode          = var.launch_type_compatibility == "FARGATE" ? "awsvpc" : var.network_mode

}

resource "aws_ecs_cluster" "this" {

  count = var.ecs_cluster-create ? 1 : 0

  name = "${local.resource_name_pattern}_ecs_cluster"
  tags = merge({
    resource_name  = "${local.resource_name_pattern}_ecs_cluster"
  }, var.tags)

}

resource "aws_ecs_service" "this" {
  count = var.ecs_service-create ? 1 : 0

  name                               = "${local.resource_name_pattern}-ecs_service"
  task_definition                    = aws_ecs_task_definition.this[count.index].arn
  iam_role                           = var.ecs_service-iam_role
  desired_count                      = var.ecs_service-desired_count
  cluster                            = aws_ecs_cluster.this[count.index].id
  health_check_grace_period_seconds  = var.ecs_service-health_check_grace_period_seconds
  wait_for_steady_state              = var.ecs_service-wait_for_steady_state
  force_new_deployment               = var.ecs_service-force_new_deployment

  launch_type      = var.ecs_service-capacity_provider_strategies == [] ? null : var.ecs_service-launch_type
  platform_version = var.ecs_service-platform_version

  dynamic "capacity_provider_strategy" {
    for_each = var.ecs_service-capacity_provider_strategies != [] ? var.ecs_service-capacity_provider_strategies : []

    content {
      base              = lookup(capacity_provider_strategy.value, "base", null)
      weight            = capacity_provider_strategy.value.weight
      capacity_provider = capacity_provider_strategy.value.capacity_provider
    }
  }

  dynamic "network_configuration" {
    for_each = var.ecs_service-network_configuration == null ? [] : tolist([var.ecs_service-network_configuration])

    content {
      security_groups  = network_configuration.value.security_groups
      subnets          = network_configuration.value.subnets
      assign_public_ip = network_configuration.value.assign_public_ip
    }
  }

  dynamic "load_balancer" {
    for_each = tolist([var.load_balancer-target_groups])

    content {
      container_name   = load_balancer.value.container_name
      target_group_arn = load_balancer.value.target_group_arn
      container_port   = load_balancer.value.container_port
    }
  }

  tags           = var.tags
  propagate_tags = "TASK_DEFINITION"
}

resource "aws_ecs_task_definition" "this" {
  count = var.task_definition-create ? 1 : 0

  family                = "${local.resource_name_pattern}-task_definition"
  container_definitions = var.container_definitions
  network_mode          = local.network_mode

  cpu                      = var.cpu
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn
  memory                   = var.memory
  requires_compatibilities = [var.launch_type_compatibility]

  tags = merge({
    "resource_class" = "ecs-taskdefinition",
    },
  var.tags)
}


