output "rancher_url" {
  value = local.install_rancher ? rancher2_bootstrap.admin.0.url : null
}

output "rancher_token" {
  value     = local.install_rancher ? rancher2_bootstrap.admin.0.token : null
  sensitive = true
}

output "ingress_dns_name" {
  value = aws_lb.lb[0].dns_name
}

output "sns_agent_arn" {
  value = aws_autoscaling_notification.agent-notifications.arn
}

output "sns_server_arn" {
  value = aws_autoscaling_notification.server-notifications.arn
}