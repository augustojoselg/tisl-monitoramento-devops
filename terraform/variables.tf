# Variáveis de configuração do projeto
variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado para naming dos recursos)"
  type        = string
  default     = "zabbix-monitoring"
}

variable "region" {
  description = "Região GCP onde os recursos serão criados"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona GCP onde a instância será criada"
  type        = string
  default     = "us-central1-a"
}

# Variáveis de rede
variable "subnet_cidr" {
  description = "CIDR da subnet para o Zabbix"
  type        = string
  default     = "10.0.1.0/24"
}

# Variáveis da instância
variable "machine_type" {
  description = "Tipo de máquina para o servidor Zabbix"
  type        = string
  default     = "e2-standard-4"
  validation {
    condition = can(regex("^e2-", var.machine_type)) || can(regex("^n2-", var.machine_type)) || can(regex("^c2-", var.machine_type))
    error_message = "O tipo de máquina deve ser e2, n2 ou c2."
  }
}

variable "image" {
  description = "Imagem do sistema operacional"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
  description = "Tamanho do disco de boot em GB"
  type        = number
  default     = 50
}

variable "data_disk_size" {
  description = "Tamanho do disco de dados em GB"
  type        = number
  default     = 100
}

# Variáveis de SSH
variable "ssh_user" {
  description = "Usuário SSH para acesso à instância"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Caminho para a chave pública SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Variáveis do Zabbix
variable "zabbix_version" {
  description = "Versão do Zabbix a ser instalada"
  type        = string
  default     = "7.0"
}

variable "zabbix_db_type" {
  description = "Tipo de banco de dados (mysql ou postgresql)"
  type        = string
  default     = "mysql"
  validation {
    condition     = contains(["mysql", "postgresql"], var.zabbix_db_type)
    error_message = "O tipo de banco deve ser 'mysql' ou 'postgresql'."
  }
}

variable "zabbix_db_name" {
  description = "Nome do banco de dados do Zabbix"
  type        = string
  default     = "zabbix"
}

variable "zabbix_db_user" {
  description = "Usuário do banco de dados do Zabbix"
  type        = string
  default     = "zabbix"
}

variable "zabbix_db_password" {
  description = "Senha do banco de dados do Zabbix"
  type        = string
  sensitive   = true
}

variable "zabbix_admin_user" {
  description = "Usuário administrador do Zabbix"
  type        = string
  default     = "admin"
}

variable "zabbix_admin_password" {
  description = "Senha do administrador do Zabbix"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "Senha do root do MySQL"
  type        = string
  sensitive   = true
}

# Variáveis de monitoramento
variable "notification_channels" {
  description = "Lista de canais de notificação para alertas"
  type        = list(string)
  default     = []
}

# Variáveis de tags
variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser 'dev', 'staging' ou 'prod'."
  }
}

variable "owner" {
  description = "Proprietário dos recursos"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Centro de custo"
  type        = string
  default     = "monitoring"
}
