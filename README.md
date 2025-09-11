# Zabbix 7.0 LTS - Infraestrutura como Código (Terraform)

Este projeto implementa a infraestrutura completa para um servidor Zabbix 7.0 LTS na Google Cloud Platform (GCP) usando Terraform, baseado na apostila "Zabbix 7.0 LTS - Fabio Adriano Ferreira Terleski".

## Visão Geral

O projeto cria uma infraestrutura completa na GCP incluindo:

- **Instância Compute Engine** com especificações otimizadas para Zabbix
- **Rede VPC** dedicada com firewall configurado
- **Disco adicional** para dados do Zabbix
- **IP estático** para acesso externo
- **Instalação automática** do Zabbix 7.0 LTS com MySQL
- **Configuração completa** de serviços e monitoramento
- **Backup automático** configurado

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Google Cloud Platform                    │
├─────────────────────────────────────────────────────────────┤
│  VPC Network (zabbix-network)                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Subnet (10.0.1.0/24)                                  │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  Compute Instance (e2-standard-4)                   │ │ │
│  │  │  ┌─────────────────────────────────────────────────┐ │ │ │
│  │  │  │  Ubuntu 22.04 LTS                               │ │ │ │
│  │  │  │  ├── Zabbix Server 7.0 LTS                      │ │ │ │
│  │  │  │  ├── Zabbix Agent                               │ │ │ │
│  │  │  │  ├── MySQL 8.0                                  │ │ │ │
│  │  │  │  ├── Apache 2.4                                 │ │ │ │
│  │  │  │  ├── PHP 8.1                                    │ │ │ │
│  │  │  │  └── Disco de Dados (100GB)                     │ │ │ │
│  │  │  └─────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  Firewall Rules:                                            │
│  ├── SSH (22)                                               │
│  ├── HTTP (80)                                              │
│  ├── HTTPS (443)                                            │
│  ├── Zabbix Agent (10050)                                   │
│  └── Zabbix Server (10051)                                  │
└─────────────────────────────────────────────────────────────┘
```

## Pré-requisitos

### 1. Ferramentas Necessárias

- **Terraform** >= 1.0
- **Google Cloud SDK** (gcloud)
- **Chave SSH** configurada
- **Conta GCP** com billing habilitado

### 2. Configuração do GCP

```bash
# Autenticar no GCP
gcloud auth login

# Configurar projeto padrão
gcloud config set project SEU_PROJECT_ID

# Habilitar APIs necessárias
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com
```

### 3. Configuração SSH

```bash
# Gerar chave SSH (se não existir)
ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com"

# Verificar se a chave existe
ls -la ~/.ssh/id_rsa.pub
```

## Estrutura do Projeto

```
tisl-monitoramento-devops/
├── terraform/
│   ├── main.tf                    # Configuração principal da infraestrutura
│   ├── variables.tf               # Definição de variáveis
│   ├── outputs.tf                 # Outputs do Terraform
│   ├── terraform.tfvars.example   # Exemplo de configuração
│   └── scripts/
│       └── install-zabbix.sh      # Script de instalação automática
├── Apostila Zabbix 7.0 LTS.pdf    # Documentação de referência
└── README.md                      # Este arquivo
```

## Configuração

### 1. Configurar Variáveis

```bash
# Copiar arquivo de exemplo
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Editar configurações
nano terraform/terraform.tfvars
```

### 2. Variáveis Principais

```hcl
# Obrigatório
project_id = "seu-projeto-gcp-id"

# Opcional (valores padrão recomendados)
project_name = "zabbix-monitoring"
region = "us-central1"
zone = "us-central1-a"
machine_type = "e2-standard-4"
data_disk_size = 100
```

## Deploy

### 1. Inicializar Terraform

```bash
cd terraform
terraform init
```

### 2. Planejar Deploy

```bash
terraform plan
```

### 3. Aplicar Infraestrutura

```bash
terraform apply
```

### 4. Aguardar Instalação

A instalação completa leva aproximadamente **15-20 minutos**. Você pode acompanhar o progresso:

```bash
# Conectar via SSH
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw zabbix_external_ip)

# Verificar logs de instalação
sudo tail -f /var/log/zabbix-install.log

# Verificar status dos serviços
sudo systemctl status zabbix-server
sudo systemctl status zabbix-agent
sudo systemctl status apache2
```

## Acesso ao Zabbix

Após a instalação, acesse:

- **URL**: `http://SEU_IP_EXTERNO/zabbix`
- **Usuário**: `admin`
- **Senha**: `var.zabbix_admin_password`

### Obter Informações de Acesso

```bash
# Ver outputs do Terraform
terraform output

# Ver informações de acesso
terraform output zabbix_web_url
terraform output ssh_connection_command
```

## Especificações da Instância

### Recursos Padrão

- **Tipo**: e2-standard-4
- **vCPUs**: 4
- **RAM**: 16 GB
- **Disco Boot**: 50 GB (SSD)
- **Disco Dados**: 100 GB (SSD)
- **Sistema**: Ubuntu 22.04 LTS

### Recursos Recomendados por Ambiente

| Ambiente | Tipo de Máquina | vCPUs | RAM | Disco Dados |
|----------|----------------|-------|-----|-------------|
| **Desenvolvimento** | e2-standard-2 | 2 | 8 GB | 50 GB |
| **Produção Pequena** | e2-standard-4 | 4 | 16 GB | 100 GB |
| **Produção Média** | e2-standard-8 | 8 | 32 GB | 500 GB |
| **Produção Grande** | n2-standard-16 | 16 | 64 GB | 1 TB |

## Configurações Pós-Instalação

### 1. Alterar Senhas Padrão

```bash
# Conectar via SSH
ssh -i ~/.ssh/id_rsa ubuntu@SEU_IP

# Alterar senha do MySQL
sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD
ALTER USER 'root'@'localhost' IDENTIFIED BY 'nova_senha_root';
ALTER USER 'zabbix'@'localhost' IDENTIFIED BY 'nova_senha_zabbix';
FLUSH PRIVILEGES;
EXIT;

# Alterar senha do admin do Zabbix (via interface web)
# Acesse: http://SEU_IP/zabbix
# Usuário: admin, Senha: [sua_senha_configurada]
# Vá em Administration > Users > admin > Change password
```

### 2. Configurar SSL/HTTPS

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-apache -y

# Obter certificado SSL
sudo certbot --apache -d SEU_DOMINIO

# Testar renovação automática
sudo certbot renew --dry-run
```

### 3. Configurar Backup

O backup automático já está configurado e executa diariamente às 2h da manhã:

```bash
# Verificar configuração do cron
sudo crontab -l

# Executar backup manual
sudo /usr/local/bin/zabbix-backup.sh

# Verificar backups
ls -la /var/backups/zabbix/
```

## Monitoramento

### 1. Verificar Status dos Serviços

```bash
# Status geral
sudo systemctl status zabbix-server zabbix-agent apache2

# Logs em tempo real
sudo tail -f /var/log/zabbix/zabbix_server.log
sudo tail -f /var/log/zabbix/zabbix_agentd.log
sudo tail -f /var/log/apache2/error.log
```

### 2. Métricas de Performance

```bash
# Uso de CPU e Memória
htop

# Uso de disco
df -h

# Conexões de rede
netstat -tulpn | grep -E ':(80|443|10050|10051)'
```

### 3. Alertas GCP

O projeto inclui configuração de alertas no Google Cloud Monitoring para:
- Instância indisponível
- Uso alto de CPU
- Uso alto de memória
- Uso alto de disco

## Manutenção

### 1. Atualizações

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Atualizar Zabbix (quando disponível)
sudo apt update
sudo apt upgrade zabbix-server-mysql zabbix-frontend-php zabbix-agent
```

### 2. Backup e Restore

```bash
# Backup manual
sudo /usr/local/bin/zabbix-backup.sh

# Restore do banco (em caso de necessidade)
sudo mysql -u zabbix -p zabbix < /var/backups/zabbix/zabbix_db_YYYYMMDD_HHMMSS.sql
```

### 3. Limpeza de Logs

```bash
# Limpar logs antigos
sudo find /var/log -name "*.log" -mtime +30 -delete
sudo find /var/log -name "*.gz" -mtime +30 -delete
```

## Destruir Infraestrutura

```bash
# Destruir todos os recursos
terraform destroy

# Confirmar destruição
yes
```

**ATENÇÃO**: Esta operação é irreversível e removerá todos os dados!

## Solução de Problemas

### Problemas Comuns

1. **Erro de autenticação GCP**
   ```bash
   gcloud auth application-default login
   ```

2. **Chave SSH não encontrada**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com"
   ```

3. **Zabbix não inicia**
   ```bash
   sudo systemctl restart zabbix-server
   sudo journalctl -u zabbix-server -f
   ```

4. **Banco de dados não conecta**
   ```bash
   sudo systemctl restart mysql
   sudo mysql -u zabbix -p -e "SHOW DATABASES;"
   ```

### Logs Importantes

- **Instalação**: `/var/log/zabbix-install.log`
- **Zabbix Server**: `/var/log/zabbix/zabbix_server.log`
- **Zabbix Agent**: `/var/log/zabbix/zabbix_agentd.log`
- **Apache**: `/var/log/apache2/error.log`
- **MySQL**: `/var/log/mysql/error.log`

## Recursos Adicionais

- [Documentação Oficial do Zabbix](https://www.zabbix.com/documentation/current)
- [Apostila Zabbix 7.0 LTS - Fabio Adriano Ferreira Terleski](./Apostila%20Zabbix%207.0%20LTS%20-%20Fabio%20Adriano%20Ferreira%20Terleski.pdf)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud Documentation](https://cloud.google.com/docs)

## Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## Suporte

Para suporte e dúvidas:

- **Issues**: Abra uma issue no GitHub
- **Email**: devops-team@exemplo.com
- **Documentação**: Consulte a apostila anexa

---

**Desenvolvido pela equipe DevOps**
