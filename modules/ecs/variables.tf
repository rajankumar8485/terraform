variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_unique_id" {
  type = string
}

variable "launch_type_compatibility" {
  type = string
}

variable "network_mode" {
  type = string
}

variable "ecs_cluster-create" {
  type = bool
}

variable "ecs_service-create" {
  type = bool
}

variable "ecs_service-iam_role" {
  type = string
  default = null
}

variable "ecs_service-desired_count" {
  type = number
}

variable "ecs_service-health_check_grace_period_seconds" {
  type = number
}
variable "ecs_service-wait_for_steady_state" {
  type = bool
}

variable "ecs_service-force_new_deployment" {
  type = bool
}

variable "ecs_service-capacity_provider_strategies" {
  type = list(any)
  default = []
}

variable "ecs_service-launch_type" {
  type = string
}

variable "ecs_service-platform_version" {
  type = string
  default = null
}

variable "ecs_service-network_configuration" {
  type = map(any)
}

variable "load_balancer-target_groups" {
  type = map(any)
}

variable "task_definition-create" {
  type = bool
}

variable "container_definitions" {
  type = any
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "task_role_arn" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}