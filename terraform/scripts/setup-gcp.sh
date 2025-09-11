#!/bin/bash

# Script para configurar o ambiente GCP antes do deploy
# Este script deve ser executado antes de rodar o terraform

set -e

echo "=========================================="
echo "Configuração do Ambiente GCP"
echo "=========================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Verificar se o gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Google Cloud SDK não está instalado!${NC}"
    echo "Instale seguindo: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

print_status 0 "Google Cloud SDK encontrado"

# Verificar se está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}Você não está autenticado no GCP${NC}"
    echo "Executando gcloud auth login..."
    gcloud auth login
fi

print_status 0 "Autenticação GCP OK"

# Solicitar ID do projeto
read -p "Digite o ID do projeto GCP: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ID do projeto é obrigatório!${NC}"
    exit 1
fi

# Configurar projeto
echo "Configurando projeto: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Verificar se o projeto existe e está ativo
if ! gcloud projects describe $PROJECT_ID &> /dev/null; then
    echo -e "${RED}Projeto $PROJECT_ID não encontrado ou sem acesso!${NC}"
    exit 1
fi

print_status 0 "Projeto $PROJECT_ID configurado"

# Habilitar APIs necessárias
echo "Habilitando APIs necessárias..."

APIS=(
    "compute.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "cloudresourcemanager.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "Habilitando $api..."
    gcloud services enable $api
    print_status 0 "$api habilitada"
done

# Verificar billing
echo "Verificando billing..."
if gcloud billing projects describe $PROJECT_ID --format="value(billingEnabled)" | grep -q "True"; then
    print_status 0 "Billing habilitado"
else
    echo -e "${RED}Billing não está habilitado para o projeto!${NC}"
    echo "Habilite o billing em: https://console.cloud.google.com/billing"
    exit 1
fi

# Configurar Application Default Credentials
echo "Configurando Application Default Credentials..."
gcloud auth application-default login

print_status 0 "Application Default Credentials configurado"

# Verificar se a chave SSH existe
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${YELLOW}Chave SSH não encontrada em $SSH_KEY_PATH${NC}"
    read -p "Deseja gerar uma nova chave SSH? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_rsa" -N ""
        print_status 0 "Chave SSH gerada"
    else
        echo -e "${RED}Chave SSH é obrigatória para o deploy!${NC}"
        exit 1
    fi
else
    print_status 0 "Chave SSH encontrada"
fi

# Criar arquivo terraform.tfvars se não existir
TFVARS_FILE="terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo "Criando arquivo terraform.tfvars..."
    cat > "$TFVARS_FILE" << EOF
# Configuração do projeto GCP
project_id = "$PROJECT_ID"

# Configurações do projeto
project_name = "zabbix-monitoring"
region = "us-central1"
zone = "us-central1-a"

# Configurações da instância
machine_type = "e2-standard-4"
boot_disk_size = 50
data_disk_size = 100

# Configurações SSH
ssh_user = "ubuntu"
ssh_public_key_path = "$SSH_KEY_PATH"

# Configurações do Zabbix
zabbix_version = "7.0"
zabbix_db_type = "mysql"
zabbix_db_name = "zabbix"
zabbix_db_user = "zabbix"
zabbix_db_password = "sua_senha_segura_aqui"
zabbix_admin_user = "admin"
zabbix_admin_password = "sua_senha_admin_segura_aqui"

# Tags
environment = "prod"
owner = "devops-team"
cost_center = "monitoring"
EOF
    print_status 0 "Arquivo terraform.tfvars criado"
else
    print_warning "Arquivo terraform.tfvars já existe"
fi

# Verificar se o Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform não está instalado!${NC}"
    echo "Instale seguindo: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

print_status 0 "Terraform encontrado"

# Verificar versão do Terraform
TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
echo "Versão do Terraform: $TERRAFORM_VERSION"

# Inicializar Terraform
echo "Inicializando Terraform..."
terraform init

print_status 0 "Terraform inicializado"

echo ""
echo "=========================================="
echo "Configuração concluída com sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Revisar o arquivo terraform.tfvars"
echo "2. Executar: terraform plan"
echo "3. Executar: terraform apply"
echo ""
echo "Informações importantes:"
echo "- Projeto GCP: $PROJECT_ID"
echo "- Região: us-central1"
echo "- Zona: us-central1-a"
echo "- Chave SSH: $SSH_KEY_PATH"
echo ""
