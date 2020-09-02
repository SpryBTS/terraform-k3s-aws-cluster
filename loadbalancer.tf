resource "random_pet" "lb" {
    length = 1
}

resource "aws_lb" "server-lb" {
  name               = substr("${local.name}-int-${random_pet.lb.id}", 0, 24)
  internal           = true
  load_balancer_type = "network"
  subnets            = local.private_subnets
}

resource "aws_lb_listener" "server-port_6443" {
  load_balancer_arn = aws_lb.server-lb.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server-6443.arn
  }
}

resource "aws_lb_target_group" "server-6443" {
  name     = substr("${local.name}-6443-${random_pet.lb.id}", 0, 24)
  port     = 6443
  protocol = "TCP"

  vpc_id   = data.aws_vpc.default.id
}


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
  for_each = (local.create_external_nlb == 1) ? toset(local.external_ports) : []

  load_balancer_arn = aws_lb.lb.0.arn
  port              = each.value
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.agent[each.value].arn
  }
}

resource "aws_lb_target_group" "agent" {
  for_each = (local.create_external_nlb == 1) ? toset(local.external_ports) : []

  name     = substr("${local.name}-${each.value}-${random_pet.lb.id}", 0, 24)
  port     = each.value
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
