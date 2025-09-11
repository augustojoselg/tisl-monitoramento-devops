# Guia de Deploy - Zabbix 7.0 LTS na GCP

## Deploy Rápido

### 1. Configuração Inicial

```bash
# Clonar o repositório
git clone <seu-repositorio>
cd tisl-monitoramento-devops

# Configurar ambiente GCP
make setup-gcp
```

### 2. Deploy da Infraestrutura

```bash
# Deploy completo
make prod-deploy

# Ou passo a passo
make init
make plan
make apply
```

### 3. Acesso ao Zabbix

```bash
# Obter informações de acesso
make info

# Conectar via SSH
make ssh

# Verificar status
make status
```

## Checklist de Deploy

- [ ] Projeto GCP configurado
- [ ] APIs habilitadas
- [ ] Chave SSH configurada
- [ ] Arquivo terraform.tfvars criado
- [ ] Terraform inicializado
- [ ] Deploy executado
- [ ] Zabbix acessível
- [ ] Serviços funcionando
- [ ] Backup configurado

## Comandos Úteis

```bash
# Ver logs de instalação
make logs

# Validar instalação
make validate-install

# Executar backup
make backup

# Monitorar recursos
make monitor

# Reiniciar serviços
make restart
```

## Especificações da Instância

- **Tipo**: e2-standard-4 (4 vCPUs, 16 GB RAM)
- **Disco**: 50 GB boot + 100 GB dados
- **Sistema**: Ubuntu 22.04 LTS
- **Zabbix**: 7.0 LTS
- **Banco**: MySQL 8.0
- **Web**: Apache 2.4 + PHP 8.1

## URLs de Acesso

- **Zabbix Web**: http://IP_EXTERNO/zabbix
- **Usuário**: admin
- **Senha**: [configurada em terraform.tfvars]

## Segurança

**IMPORTANTE**: Alterar senhas padrão após o deploy:

1. Senha do MySQL root
2. Senha do usuário zabbix do MySQL
3. Senha do admin do Zabbix
4. Configurar SSL/HTTPS

## Monitoramento

- Backup automático diário às 2h
- Logs centralizados
- Alertas GCP configurados
- Health checks automáticos

## Suporte

- Logs: `/var/log/zabbix-install.log`
- Status: `make status`
- Validação: `make validate-install`
- SSH: `make ssh`
