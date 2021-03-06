output "rancher_url" {
  value = local.install_rancher ? rancher2_bootstrap.admin.0.url : null
}

output "rancher_token" {
  value     = local.install_rancher ? rancher2_bootstrap.admin.0.token : null
  sensitive = true
}

output "rancher_admin_password" {
  value     = local.install_rancher ? rancher2_bootstrap.admin.0.password : null
  sensitive = true
}

output "ingress_dns_name" {
  value = aws_lb.lb[0].dns_name
}

output "internal_dns_name" {
  value = aws_lb.int-lb.dns_name
}

output "internal_zone_id" {
  value = aws_lb.int-lb.zone_id
}