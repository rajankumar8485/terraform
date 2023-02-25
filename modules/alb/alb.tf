locals {
  resource_name_pattern = replace(join("-", ["${var.region}", "${var.environment}", "${var.resource_unique_id}"]), "/_*||", "")
}

resource "aws_lb" "this" {
  count = var.alb-create ? 1 : 0

  name               = trim(substr("${local.resource_name_pattern}-alb", 0, 32), "-")
  internal           = var.alb-type == "internal" ? true : false
  load_balancer_type = var.load_balancer_type
  security_groups    = var.alb-security_group_ids
  subnets            = var.alb-subnet_ids
  idle_timeout       = var.alb-idle_timeout

  tags = merge({
    "Name" = substr(local.resource_name_pattern, 0, 32),
  }, var.tags)
}

resource "aws_lb_target_group" "this" {
  count = var.alb-create ? 1 : 0

  name     = trim(substr("${local.resource_name_pattern}-tg", 0, 32), "-")
  vpc_id   = var.alb-vpc_id
  port     = var.target_type != "lambda" ? var.alb_port : null
  protocol = var.target_type != "lambda" ? var.protocol : null

  target_type          = var.target_type
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled  = var.health_check-enabled
    protocol = var.alb_port
    interval = var.health_check-interval
  }

  tags = merge({
    "resource_name" = substr("${local.resource_name_pattern}-tg", 0, 32),
  }, var.tags)

  depends_on = [aws_lb.this]
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.alb-create ? 1 : 0

  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = aws_lb.this[0].arn
  port             = var.alb_port

}