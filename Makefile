# Makefile para o projeto Zabbix 7.0 LTS - Infraestrutura como Código
# Facilita a execução de comandos comuns do Terraform

.PHONY: help init plan apply destroy validate setup-gcp clean

# Variáveis
TERRAFORM_DIR = terraform
SCRIPTS_DIR = $(TERRAFORM_DIR)/scripts

# Cores para output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Mostra esta ajuda
	@echo "$(GREEN)Zabbix 7.0 LTS - Infraestrutura como Código$(NC)"
	@echo "=========================================="
	@echo ""
	@echo "Comandos disponíveis:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Exemplos de uso:"
	@echo "  make setup-gcp    # Configurar ambiente GCP"
	@echo "  make init         # Inicializar Terraform"
	@echo "  make plan         # Planejar deploy"
	@echo "  make apply        # Aplicar infraestrutura"
	@echo "  make destroy      # Destruir infraestrutura"

setup-gcp: ## Configurar ambiente GCP (autenticação, APIs, etc.)
	@echo "$(GREEN)Configurando ambiente GCP...$(NC)"
	@cd $(TERRAFORM_DIR) && ./scripts/setup-gcp.sh

init: ## Inicializar Terraform
	@echo "$(GREEN)Inicializando Terraform...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init

validate: ## Validar configuração do Terraform
	@echo "$(GREEN)Validando configuração do Terraform...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform validate

format: ## Formatar arquivos do Terraform
	@echo "$(GREEN)Formatando arquivos do Terraform...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform fmt -recursive

plan: ## Planejar deploy da infraestrutura
	@echo "$(GREEN)Planejando deploy da infraestrutura...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform plan

apply: ## Aplicar infraestrutura
	@echo "$(GREEN)Aplicando infraestrutura...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform apply

apply-auto: ## Aplicar infraestrutura automaticamente (sem confirmação)
	@echo "$(GREEN)Aplicando infraestrutura automaticamente...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform apply -auto-approve

destroy: ## Destruir infraestrutura
	@echo "$(RED)Destruindo infraestrutura...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform destroy

destroy-auto: ## Destruir infraestrutura automaticamente (sem confirmação)
	@echo "$(RED)Destruindo infraestrutura automaticamente...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

output: ## Mostrar outputs do Terraform
	@echo "$(GREEN)Outputs do Terraform:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform output

output-json: ## Mostrar outputs do Terraform em formato JSON
	@echo "$(GREEN)Outputs do Terraform (JSON):$(NC)"
	@cd $(TERRAFORM_DIR) && terraform output -json

show: ## Mostrar estado atual do Terraform
	@echo "$(GREEN)Estado atual do Terraform:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform show

refresh: ## Atualizar estado do Terraform
	@echo "$(GREEN)Atualizando estado do Terraform...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform refresh

clean: ## Limpar arquivos temporários do Terraform
	@echo "$(YELLOW)Limpando arquivos temporários...$(NC)"
	@cd $(TERRAFORM_DIR) && rm -rf .terraform/ .terraform.lock.hcl terraform.tfstate* crash.log

ssh: ## Conectar via SSH ao servidor Zabbix
	@echo "$(GREEN)Conectando via SSH ao servidor Zabbix...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip)

url: ## Mostrar URL de acesso ao Zabbix
	@echo "$(GREEN)URL de acesso ao Zabbix:$(NC)"
	@cd $(TERRAFORM_DIR) && echo "http://$$(terraform output -raw zabbix_external_ip)/zabbix"

info: ## Mostrar informações de acesso
	@echo "$(GREEN)Informações de acesso:$(NC)"
	@echo "=========================================="
	@cd $(TERRAFORM_DIR) && \
		echo "URL: http://$$(terraform output -raw zabbix_external_ip)/zabbix" && \
		echo "Usuário: admin" && \
		echo "Senha: zabbix123" && \
		echo "SSH: ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip)"

logs: ## Ver logs de instalação do Zabbix
	@echo "$(GREEN)Visualizando logs de instalação...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "sudo tail -f /var/log/zabbix-install.log"

status: ## Verificar status dos serviços
	@echo "$(GREEN)Verificando status dos serviços...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "sudo systemctl status zabbix-server zabbix-agent apache2"

validate-install: ## Validar instalação do Zabbix
	@echo "$(GREEN)Validando instalação do Zabbix...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "sudo ./scripts/validate-installation.sh"

backup: ## Executar backup manual do Zabbix
	@echo "$(GREEN)Executando backup manual...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "sudo /usr/local/bin/zabbix-backup.sh"

# Comandos de desenvolvimento
dev-setup: ## Configuração completa para desenvolvimento
	@echo "$(GREEN)Configuração completa para desenvolvimento...$(NC)"
	@make setup-gcp
	@make init
	@make validate
	@make format

prod-deploy: ## Deploy completo para produção
	@echo "$(GREEN)Deploy completo para produção...$(NC)"
	@make validate
	@make plan
	@make apply

# Comandos de manutenção
update: ## Atualizar sistema e Zabbix
	@echo "$(GREEN)Atualizando sistema e Zabbix...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "sudo apt update && sudo apt upgrade -y"

restart: ## Reiniciar serviços do Zabbix
	@echo "$(GREEN)Reiniciando serviços do Zabbix...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "sudo systemctl restart zabbix-server zabbix-agent apache2"

# Comandos de monitoramento
monitor: ## Monitorar recursos do servidor
	@echo "$(GREEN)Monitorando recursos do servidor...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "htop"

disk-usage: ## Verificar uso de disco
	@echo "$(GREEN)Verificando uso de disco...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "df -h"

memory-usage: ## Verificar uso de memória
	@echo "$(GREEN)Verificando uso de memória...$(NC)"
	@cd $(TERRAFORM_DIR) && ssh -i ~/.ssh/id_rsa ubuntu@$$(terraform output -raw zabbix_external_ip) "free -h"

# Comandos de documentação
docs: ## Gerar documentação
	@echo "$(GREEN)Gerando documentação...$(NC)"
	@echo "Documentação disponível em README.md"

# Comandos de teste
test: ## Executar testes
	@echo "$(GREEN)Executando testes...$(NC)"
	@make validate
	@make plan

# Comando padrão
.DEFAULT_GOAL := help
