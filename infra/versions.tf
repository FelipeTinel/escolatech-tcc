terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
  }

  # Recomendado para trabalho em equipe: state remoto (crie o bucket antes).
  # backend "s3" {
  #   bucket       = "escola-tech-tfstate-<sufixo-unico>"
  #   key          = "prod/terraform.tfstate"
  #   region       = "sa-east-1"
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
