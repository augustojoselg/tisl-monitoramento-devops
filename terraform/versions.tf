# Versões do Terraform e Providers
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.3"
    }
  }

  # Backend para armazenar o state (opcional)
  # Descomente e configure conforme necessário
  # backend "gcs" {
  #   bucket = "seu-bucket-terraform-state"
  #   prefix = "zabbix-infrastructure"
  # }
}
