resource "random_pet" "lb" {
    length = 1
}

# Internal Load Balancer configuration
#
# 
resource "aws_lb" "int-lb" {
  name               = substr("${local.name}-int-${random_pet.lb.id}", 0, 24)
  internal           = true
  load_balancer_type = "network"
  subnets            = local.private_subnets
}

resource "aws_lb_listener" "server-port" {
  depends_on = [ aws_lb_target_group.server-int ]

  for_each = (local.create_internal_nlb == 1) ? local.internal_server_ports : []

  load_balancer_arn = aws_lb.int-lb.arn
  port              = each.key
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server-ext[each.key].arn
  }
}

resource "aws_lb_listener" "agent-port" {
  depends_on = [ aws_lb_target_group.agent ]

  for_each = (local.create_internal_nlb == 1) ? local.internal_agent_ports : []

  load_balancer_arn = aws_lb.int-lb.arn
  port              = each.key
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.agent-int[each.key].arn
  }
}

resource "aws_lb_target_group" "server-int" {
  for_each = (local.create_internal_nlb == 1) ? local.internal_server_ports : []

  name     = substr("${local.name}-${each.key}-${random_pet.lb.id}", 0, 24)
  port     = each.key
  protocol = "TCP"

  vpc_id   = data.aws_vpc.default.id

  health_check {
    interval            = 30
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    "kubernetes.io/cluster/${local.name}" = ""
  }
}

resource "aws_lb_target_group" "agent-int" {
  for_each = (local.create_internal_nlb == 1) ? local.internal_agent_ports : []

  name     = substr("${local.name}-${each.key}-${random_pet.lb.id}", 0, 24)
  port     = each.key
  protocol = "TCP"

  vpc_id   = data.aws_vpc.default.id

  health_check {
    interval            = 10
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    "kubernetes.io/cluster/${local.name}" = ""
  }
}

# External Load Balancer configuration
resource "aws_lb" "lb" {
  count              = local.create_external_nlb
  name               = substr("${local.name}-ext-${random_pet.lb.id}", 0, 24)
  internal           = false
  load_balancer_type = "network"
  subnets            = local.public_subnets

  tags = {
    "kubernetes.io/cluster/${local.name}" = ""
  }
}

resource "aws_lb_listener" "port" {
  depends_on = [ aws_lb_target_group.agent ]

  for_each = (local.create_external_nlb == 1) ? local.external_ports : []

  load_balancer_arn = aws_lb.lb.0.arn
  port              = each.key
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.agent[each.key].arn
  }
}

resource "aws_lb_target_group" "agent" {
  for_each = (local.create_external_nlb == 1) ? local.external_ports : []

  name     = substr("${local.name}-${each.key}-${random_pet.lb.id}", 0, 24)
  port     = each.key
  protocol = "TCP"

  vpc_id   = data.aws_vpc.default.id

  health_check {
    interval            = 10
    timeout             = 6
    path                = local.ingress_check_path
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = {
    "kubernetes.io/cluster/${local.name}" = ""
  }
}

resource "aws_lb_target_group" "server-ext" {
  for_each = (local.create_external_nlb == 1) ? local.external_ports : []

  name     = substr("${local.name}-${each.key}-${random_pet.lb.id}", 0, 24)
  port     = each.key
  protocol = "TCP"

  vpc_id   = data.aws_vpc.default.id

  health_check {
    interval            = 10
    timeout             = 6
    path                = local.ingress_check_path
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = {
    "kubernetes.io/cluster/${local.name}" = ""
  }
}
