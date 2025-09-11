#!/bin/bash

# Script de instalação do Zabbix 7.0 LTS no Ubuntu 22.04
# Este script é executado automaticamente durante o boot da instância

set -e

# Configurações (serão substituídas pelo Terraform)
ZABBIX_VERSION="${zabbix_version:-7.0}"
ZABBIX_DB_TYPE="${zabbix_db_type:-mysql}"
ZABBIX_DB_NAME="${zabbix_db_name:-zabbix}"
ZABBIX_DB_USER="${zabbix_db_user:-zabbix}"
ZABBIX_DB_PASSWORD="${zabbix_db_password}"
ZABBIX_ADMIN_USER="${zabbix_admin_user:-admin}"
ZABBIX_ADMIN_PASSWORD="${zabbix_admin_password}"
MYSQL_ROOT_PASSWORD="${mysql_root_password}"

# Log de instalação
LOG_FILE="/var/log/zabbix-install.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "=========================================="
echo "Iniciando instalação do Zabbix $ZABBIX_VERSION LTS"
echo "Data: $(date)"
echo "=========================================="

# Atualizar sistema
echo "Atualizando sistema..."
apt-get update -y
apt-get upgrade -y

# Instalar dependências básicas
echo "Instalando dependências básicas..."
apt-get install -y \
    wget \
    curl \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    unzip \
    htop \
    vim \
    net-tools

# Configurar timezone
echo "Configurando timezone..."
timedatectl set-timezone America/Sao_Paulo

# Montar disco de dados
echo "Configurando disco de dados..."
DISK_DEVICE="/dev/sdb"
MOUNT_POINT="/var/lib/zabbix"

# Verificar se o disco existe
if [ -b "$DISK_DEVICE" ]; then
    echo "Disco de dados encontrado: $DISK_DEVICE"

    # Formatar o disco se necessário
    if ! blkid "$DISK_DEVICE" > /dev/null 2>&1; then
        echo "Formatando disco de dados..."
        mkfs.ext4 "$DISK_DEVICE"
    fi

    # Criar ponto de montagem
    mkdir -p "$MOUNT_POINT"

    # Montar o disco
    mount "$DISK_DEVICE" "$MOUNT_POINT"

    # Adicionar ao fstab para montagem automática
    echo "$DISK_DEVICE $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab

    # Ajustar permissões
    chown zabbix:zabbix "$MOUNT_POINT" 2>/dev/null || true
    chmod 755 "$MOUNT_POINT"

    echo "Disco de dados configurado com sucesso"
else
    echo "Disco de dados não encontrado, usando armazenamento padrão"
    MOUNT_POINT="/var/lib/zabbix"
    mkdir -p "$MOUNT_POINT"
fi

# Instalar MySQL
echo "Instalando MySQL..."
apt-get install -y mysql-server mysql-client

# Configurar MySQL
echo "Configurando MySQL..."
systemctl start mysql
systemctl enable mysql

# Configurar senha root do MySQL
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${mysql_root_password}';"
mysql -e "FLUSH PRIVILEGES;"

# Criar banco de dados e usuário do Zabbix
echo "Criando banco de dados do Zabbix..."
mysql -uroot -p${mysql_root_password} -e "CREATE DATABASE $ZABBIX_DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
mysql -uroot -p${mysql_root_password} -e "CREATE USER '$ZABBIX_DB_USER'@'localhost' IDENTIFIED BY '$ZABBIX_DB_PASSWORD';"
mysql -uroot -p${mysql_root_password} -e "GRANT ALL PRIVILEGES ON $ZABBIX_DB_NAME.* TO '$ZABBIX_DB_USER'@'localhost';"
mysql -uroot -p${mysql_root_password} -e "FLUSH PRIVILEGES;"

# Adicionar repositório do Zabbix
echo "Adicionando repositório do Zabbix..."
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_7.0-1+ubuntu22.04_all.deb
apt-get update

# Instalar Zabbix Server, Frontend e Agent
echo "Instalando Zabbix Server, Frontend e Agent..."
apt-get install -y \
    zabbix-server-mysql \
    zabbix-frontend-php \
    zabbix-apache-conf \
    zabbix-sql-scripts \
    zabbix-agent

# Instalar PHP e Apache
echo "Instalando PHP e Apache..."
apt-get install -y \
    apache2 \
    php \
    php-mysql \
    php-ldap \
    php-bcmath \
    php-mbstring \
    php-gd \
    php-pdo \
    php-xml \
    php-cli \
    php-curl \
    php-zip \
    php-intl

# Configurar PHP
echo "Configurando PHP..."
PHP_INI="/etc/php/8.1/apache2/php.ini"
sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' "$PHP_INI"
sed -i 's/max_execution_time = 30/max_execution_time = 300/' "$PHP_INI"
sed -i 's/memory_limit = 128M/memory_limit = 256M/' "$PHP_INI"
sed -i 's/post_max_size = 8M/post_max_size = 16M/' "$PHP_INI"
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2M/' "$PHP_INI"
sed -i 's/max_input_time = 60/max_input_time = 300/' "$PHP_INI"

# Importar schema inicial do Zabbix
echo "Importando schema inicial do Zabbix..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u"$ZABBIX_DB_USER" -p"$ZABBIX_DB_PASSWORD" "$ZABBIX_DB_NAME"

# Configurar Zabbix Server
echo "Configurando Zabbix Server..."
ZABBIX_CONF="/etc/zabbix/zabbix_server.conf"
sed -i "s/# DBHost=localhost/DBHost=localhost/" "$ZABBIX_CONF"
sed -i "s/# DBName=zabbix/DBName=$ZABBIX_DB_NAME/" "$ZABBIX_CONF"
sed -i "s/# DBUser=zabbix/DBUser=$ZABBIX_DB_USER/" "$ZABBIX_CONF"
sed -i "s/# DBPassword=/DBPassword=$ZABBIX_DB_PASSWORD/" "$ZABBIX_CONF"
sed -i "s/# StartPollers=5/StartPollers=10/" "$ZABBIX_CONF"
sed -i "s/# StartPollersUnreachable=1/StartPollersUnreachable=3/" "$ZABBIX_CONF"
sed -i "s/# StartTrappers=5/StartTrappers=5/" "$ZABBIX_CONF"
sed -i "s/# StartPingers=1/StartPingers=3/" "$ZABBIX_CONF"
sed -i "s/# StartDiscoverers=1/StartDiscoverers=3/" "$ZABBIX_CONF"
sed -i "s/# StartHTTPPollers=1/StartHTTPPollers=2/" "$ZABBIX_CONF"

# Configurar Zabbix Agent
echo "Configurando Zabbix Agent..."
ZABBIX_AGENT_CONF="/etc/zabbix/zabbix_agentd.conf"
sed -i "s/Server=127.0.0.1/Server=127.0.0.1/" "$ZABBIX_AGENT_CONF"
sed -i "s/ServerActive=127.0.0.1/ServerActive=127.0.0.1/" "$ZABBIX_AGENT_CONF"
sed -i "s/# Hostname=Zabbix server/Hostname=Zabbix server/" "$ZABBIX_AGENT_CONF"

# Configurar Apache
echo "Configurando Apache..."
a2enmod rewrite
a2enmod ssl
a2enmod headers

# Configurar virtual host do Zabbix
cat > /etc/apache2/sites-available/zabbix.conf << 'EOF'
<VirtualHost *:80>
    ServerName zabbix.local
    DocumentRoot /usr/share/zabbix

    <Directory /usr/share/zabbix>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <Directory /usr/share/zabbix/conf>
        Require all denied
    </Directory>

    <Directory /usr/share/zabbix/app>
        Require all denied
    </Directory>

    <Directory /usr/share/zabbix/include>
        Require all denied
    </Directory>

    <Directory /usr/share/zabbix/local>
        Require all denied
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/zabbix_error.log
    CustomLog ${APACHE_LOG_DIR}/zabbix_access.log combined
</VirtualHost>
EOF

# Habilitar site do Zabbix
a2ensite zabbix.conf
a2dissite 000-default.conf

# Iniciar e habilitar serviços
echo "Iniciando serviços..."
systemctl restart apache2
systemctl enable apache2

systemctl start zabbix-server
systemctl enable zabbix-server

systemctl start zabbix-agent
systemctl enable zabbix-agent

# Aguardar o Zabbix Server inicializar
echo "Aguardando Zabbix Server inicializar..."
sleep 30

# Verificar status dos serviços
echo "Verificando status dos serviços..."
systemctl status zabbix-server --no-pager
systemctl status zabbix-agent --no-pager
systemctl status apache2 --no-pager

# Configurar firewall local
echo "Configurando firewall local..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 10050/tcp
ufw allow 10051/tcp

# Criar script de backup
echo "Criando script de backup..."
cat > /usr/local/bin/zabbix-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/zabbix"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup do banco de dados
mysqldump -u zabbix -p${zabbix_db_password} zabbix > $BACKUP_DIR/zabbix_db_$DATE.sql

# Backup dos arquivos de configuração
tar -czf $BACKUP_DIR/zabbix_config_$DATE.tar.gz /etc/zabbix/

# Manter apenas os últimos 7 backups
find $BACKUP_DIR -name "zabbix_db_*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "zabbix_config_*.tar.gz" -mtime +7 -delete

echo "Backup concluído: $DATE"
EOF

chmod +x /usr/local/bin/zabbix-backup.sh

# Configurar cron para backup diário
echo "Configurando backup automático..."
echo "0 2 * * * /usr/local/bin/zabbix-backup.sh" | crontab -

# Criar arquivo de informações de acesso
echo "Criando arquivo de informações de acesso..."
cat > /root/zabbix-info.txt << EOF
==========================================
INFORMAÇÕES DE ACESSO DO ZABBIX
==========================================

URL de Acesso: http://$(curl -s ifconfig.me)/zabbix
Usuário Admin: $ZABBIX_ADMIN_USER
Senha Admin: $ZABBIX_ADMIN_PASSWORD

Banco de Dados:
- Tipo: MySQL
- Nome: $ZABBIX_DB_NAME
- Usuário: $ZABBIX_DB_USER
- Senha: $ZABBIX_DB_PASSWORD

Serviços:
- Zabbix Server: systemctl status zabbix-server
- Zabbix Agent: systemctl status zabbix-agent
- Apache: systemctl status apache2

Logs:
- Zabbix Server: /var/log/zabbix/zabbix_server.log
- Zabbix Agent: /var/log/zabbix/zabbix_agentd.log
- Apache: /var/log/apache2/

Backup:
- Script: /usr/local/bin/zabbix-backup.sh
- Diretório: /var/backups/zabbix

Data da Instalação: $(date)
==========================================
EOF

# Finalizar instalação
echo "=========================================="
echo "Instalação do Zabbix $ZABBIX_VERSION LTS concluída!"
echo "Data: $(date)"
echo "=========================================="

# Obter IP externo
EXTERNAL_IP=$(curl -s ifconfig.me)
echo "URL de acesso: http://$EXTERNAL_IP/zabbix"
echo "Usuário: $ZABBIX_ADMIN_USER"
echo "Senha: [configurada em terraform.tfvars]"
echo "=========================================="

# Marcar instalação como concluída
touch /var/log/zabbix-install-complete

echo "Instalação finalizada com sucesso!"
