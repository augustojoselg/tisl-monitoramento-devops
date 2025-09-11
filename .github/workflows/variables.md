# Arquivo de exemplo de variáveis para GitHub Actions
# Este arquivo deve ser configurado como secrets no GitHub

# Variáveis obrigatórias para o deploy:
# GCP_PROJECT_ID: ID do projeto GCP
# GCP_SA_KEY: Chave do Service Account GCP (JSON)
# ZABBIX_DB_PASSWORD: Senha do banco de dados Zabbix
# ZABBIX_ADMIN_PASSWORD: Senha do administrador Zabbix
# MYSQL_ROOT_PASSWORD: Senha do root do MySQL

# Variáveis opcionais:
# GCP_REGION: Região GCP (padrão: us-central1)
# GCP_ZONE: Zona GCP (padrão: us-central1-a)
# MACHINE_TYPE: Tipo de máquina (padrão: e2-standard-4)
# DATA_DISK_SIZE: Tamanho do disco de dados (padrão: 100)

# Para configurar as secrets no GitHub:
# 1. Vá para Settings > Secrets and variables > Actions
# 2. Clique em "New repository secret"
# 3. Adicione cada variável com seu valor correspondente

# Exemplo de configuração:
# GCP_PROJECT_ID: meu-projeto-gcp-123
# GCP_SA_KEY: {"type": "service_account", "project_id": "meu-projeto-gcp-123", ...}
# ZABBIX_DB_PASSWORD: minha_senha_zabbix_segura
# ZABBIX_ADMIN_PASSWORD: minha_senha_admin_segura
# MYSQL_ROOT_PASSWORD: minha_senha_root_mysql_segura
