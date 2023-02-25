variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_unique_id" {
  type = string
}

variable "alb-create" {
  type = bool
}

variable "alb-type" {
  type = string
}

variable "load_balancer_type" {
  type = string
}

variable "alb-security_group_ids" {
  type = list(string)
}

variable "alb-subnet_ids" {
  type = list(string)
}

variable "alb-idle_timeout" {
  type = number
}
variable "alb-vpc_id" {
  type = string
}

variable "alb_port" {
  type = number
}

variable "protocol" {
  type = string
}

variable "target_type" {
  type = string
}

variable "deregistration_delay" {
  type = number
}

variable "health_check-enabled" {
  type = true
}

variable "health_check-interval" {
  type = number
}

variable "tags" {
  type = map(string)
}