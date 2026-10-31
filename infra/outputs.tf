output "app_url" {
  description = "URL pública da aplicação"
  value       = var.enable_https ? "https://${var.domain_name}" : "http://${aws_lb.app.dns_name}"
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "ecr_repository_url" {
  description = "Destino do docker push"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_secret_arn" {
  description = "Segredo gerenciado com as credenciais do banco"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}
