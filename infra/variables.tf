############################
# Geral
############################
variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  type    = string
  default = "escola-tech"
}

variable "environment" {
  type    = string
  default = "prod"
}

############################
# Rede
############################
variable "azs" {
  description = "Availability Zones usadas (uma subnet pública e uma privada em cada)"
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1c"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "true = 1 NAT Gateway compartilhado (mais barato); false = 1 por AZ (mais resiliente)"
  type        = bool
  default     = true
}

############################
# Aplicação / Compute
############################
variable "instance_type" {
  description = "Família t4g (Graviton2/ARM64)"
  type        = string
  default     = "t4g.micro"
}

variable "app_port" {
  description = "Porta em que o container escuta"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "image_tag" {
  description = "Tag da imagem no ECR"
  type        = string
  default     = "latest"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_target" {
  description = "CPU média alvo (%) do Target Tracking"
  type        = number
  default     = 60
}

variable "deregistration_delay" {
  description = "Segundos que o ALB espera para drenar conexões ao remover um alvo"
  type        = number
  default     = 30
}

############################
# Scheduled actions
############################
variable "enable_scheduled_scaling" {
  type    = bool
  default = true
}

variable "schedule_timezone" {
  type    = string
  default = "America/Sao_Paulo"
}

variable "scale_down_cron" {
  description = "Início da madrugada (limita a capacidade máxima)"
  type        = string
  default     = "0 0 * * *"
}

variable "scale_up_cron" {
  description = "Antes do horário comercial (restaura a capacidade configurada)"
  type        = string
  default     = "0 6 * * *"
}

variable "night_max_size" {
  description = "Máximo de instâncias durante a madrugada"
  type        = number
  default     = 2
}

############################
# HTTPS / DNS
############################
variable "enable_https" {
  description = "true = ACM + Route 53 + listener 443; false = apenas HTTP (útil para testes sem domínio)"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "FQDN da aplicação (ex.: matriculas.escolatech.com.br). Obrigatório se enable_https = true"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "ID da hosted zone do Route 53. Obrigatório se enable_https = true"
  type        = string
  default     = ""
}

############################
# Banco de dados
############################
variable "db_name" {
  type    = string
  default = "escolatech"
}

variable "db_username" {
  type    = string
  default = "escolatech_admin"
}

variable "db_engine_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  description = "Limite do autoscaling de armazenamento"
  type        = number
  default     = 50
}

variable "db_multi_az" {
  description = "Réplica standby em outra AZ (alta disponibilidade opcional)"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  type    = number
  default = 7
}

variable "db_skip_final_snapshot" {
  description = "true facilita o destroy no TCC; em produção real use false"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}
