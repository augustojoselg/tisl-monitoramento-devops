# Configuração do GitHub para Deploy Automático

## Configuração de Secrets

Para que o deploy automático funcione, você precisa configurar as seguintes secrets no GitHub:

### 1. Acessar Configurações

1. Vá para o repositório no GitHub
2. Clique em **Settings**
3. No menu lateral, clique em **Secrets and variables** > **Actions**

### 2. Adicionar Secrets

Clique em **New repository secret** e adicione cada uma das seguintes:

#### Secrets Obrigatórias:

- **GCP_PROJECT_ID**: ID do seu projeto GCP
- **GCP_SA_KEY**: Chave do Service Account GCP (JSON completo)
- **ZABBIX_DB_PASSWORD**: Senha para o banco de dados Zabbix
- **ZABBIX_ADMIN_PASSWORD**: Senha do administrador Zabbix
- **MYSQL_ROOT_PASSWORD**: Senha do root do MySQL

#### Secrets Opcionais:

- **GCP_REGION**: Região GCP (padrão: us-central1)
- **GCP_ZONE**: Zona GCP (padrão: us-central1-a)
- **MACHINE_TYPE**: Tipo de máquina (padrão: e2-standard-4)
- **DATA_DISK_SIZE**: Tamanho do disco de dados (padrão: 100)

### 3. Exemplo de Configuração

```
GCP_PROJECT_ID: meu-projeto-gcp-123
GCP_SA_KEY: {"type": "service_account", "project_id": "meu-projeto-gcp-123", "private_key_id": "...", "private_key": "...", "client_email": "...", "client_id": "...", "auth_uri": "...", "token_uri": "...", "auth_provider_x509_cert_url": "...", "client_x509_cert_url": "..."}
ZABBIX_DB_PASSWORD: minha_senha_zabbix_segura_123
ZABBIX_ADMIN_PASSWORD: minha_senha_admin_segura_123
MYSQL_ROOT_PASSWORD: minha_senha_root_mysql_segura_123
```

### 4. Como Obter a Chave do Service Account

1. Acesse o [Google Cloud Console](https://console.cloud.google.com)
2. Vá para **IAM & Admin** > **Service Accounts**
3. Clique em **Create Service Account**
4. Preencha os dados:
   - **Name**: zabbix-terraform
   - **Description**: Service Account para deploy do Zabbix
5. Clique em **Create and Continue**
6. Adicione as seguintes roles:
   - **Compute Admin**
   - **Service Account User**
   - **Monitoring Metric Writer**
7. Clique em **Done**
8. Clique no service account criado
9. Vá para a aba **Keys**
10. Clique em **Add Key** > **Create new key**
11. Selecione **JSON** e clique em **Create**
12. Copie o conteúdo do arquivo JSON para a secret **GCP_SA_KEY**

### 5. Habilitar APIs Necessárias

Certifique-se de que as seguintes APIs estão habilitadas no seu projeto GCP:

- **Compute Engine API**
- **Cloud Resource Manager API**
- **Monitoring API**
- **Logging API**

### 6. Configurar Billing

Certifique-se de que o billing está habilitado no seu projeto GCP.

### 7. Testar o Deploy

Após configurar todas as secrets:

1. Faça um push para a branch `main`
2. O workflow será executado automaticamente
3. Acompanhe o progresso em **Actions**
4. Após o sucesso, você receberá as informações de acesso

### 8. Acesso ao Zabbix

Após o deploy bem-sucedido:

- **URL**: http://[IP_EXTERNO]/zabbix
- **Usuário**: admin
- **Senha**: [valor configurado em ZABBIX_ADMIN_PASSWORD]

### 9. Segurança

**IMPORTANTE**: Após o primeiro acesso:

1. Altere a senha do administrador
2. Configure SSL/HTTPS
3. Configure firewall adequadamente
4. Monitore os logs de acesso

### 10. Troubleshooting

Se o deploy falhar:

1. Verifique os logs em **Actions**
2. Confirme que todas as secrets estão configuradas
3. Verifique se as APIs estão habilitadas
4. Confirme que o billing está ativo
5. Verifique se o Service Account tem as permissões necessárias

### 11. Limpeza

Para remover a infraestrutura:

1. Execute `make destroy` localmente
2. Ou configure um workflow de destruição
3. Remova as secrets se não precisar mais delas
