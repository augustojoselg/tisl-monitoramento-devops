#!/bin/bash

# Script de validação da instalação do Zabbix
# Este script verifica se todos os componentes estão funcionando corretamente

set -e

echo "=========================================="
echo "Validação da Instalação do Zabbix 7.0 LTS"
echo "Data: $(date)"
echo "=========================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir status
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

# Contador de erros
ERRORS=0

echo "1. Verificando serviços do sistema..."

# Verificar MySQL
if systemctl is-active --quiet mysql; then
    print_status 0 "MySQL está rodando"
else
    print_status 1 "MySQL não está rodando"
    ((ERRORS++))
fi

# Verificar Apache
if systemctl is-active --quiet apache2; then
    print_status 0 "Apache está rodando"
else
    print_status 1 "Apache não está rodando"
    ((ERRORS++))
fi

# Verificar Zabbix Server
if systemctl is-active --quiet zabbix-server; then
    print_status 0 "Zabbix Server está rodando"
else
    print_status 1 "Zabbix Server não está rodando"
    ((ERRORS++))
fi

# Verificar Zabbix Agent
if systemctl is-active --quiet zabbix-agent; then
    print_status 0 "Zabbix Agent está rodando"
else
    print_status 1 "Zabbix Agent não está rodando"
    ((ERRORS++))
fi

echo ""
echo "2. Verificando conectividade de rede..."

# Verificar porta 80 (HTTP)
if netstat -tuln | grep -q ":80 "; then
    print_status 0 "Porta 80 (HTTP) está aberta"
else
    print_status 1 "Porta 80 (HTTP) não está aberta"
    ((ERRORS++))
fi

# Verificar porta 10050 (Zabbix Agent)
if netstat -tuln | grep -q ":10050 "; then
    print_status 0 "Porta 10050 (Zabbix Agent) está aberta"
else
    print_status 1 "Porta 10050 (Zabbix Agent) não está aberta"
    ((ERRORS++))
fi

# Verificar porta 10051 (Zabbix Server)
if netstat -tuln | grep -q ":10051 "; then
    print_status 0 "Porta 10051 (Zabbix Server) está aberta"
else
    print_status 1 "Porta 10051 (Zabbix Server) não está aberta"
    ((ERRORS++))
fi

echo ""
echo "3. Verificando banco de dados..."

# Configurações (serão substituídas pelo Terraform)
ZABBIX_DB_PASSWORD="${zabbix_db_password}"

# Verificar conexão com MySQL
if mysql -u zabbix -p${ZABBIX_DB_PASSWORD} -e "SELECT 1;" zabbix > /dev/null 2>&1; then
    print_status 0 "Conexão com banco de dados MySQL OK"
else
    print_status 1 "Falha na conexão com banco de dados MySQL"
    ((ERRORS++))
fi

# Verificar se as tabelas do Zabbix existem
TABLE_COUNT=$(mysql -u zabbix -p${ZABBIX_DB_PASSWORD} -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='zabbix';" zabbix 2>/dev/null | tail -n 1)
if [ "$TABLE_COUNT" -gt 100 ]; then
    print_status 0 "Tabelas do Zabbix encontradas ($TABLE_COUNT tabelas)"
else
    print_status 1 "Tabelas do Zabbix não encontradas ou incompletas"
    ((ERRORS++))
fi

echo ""
echo "4. Verificando arquivos de configuração..."

# Verificar arquivo de configuração do Zabbix Server
if [ -f "/etc/zabbix/zabbix_server.conf" ]; then
    print_status 0 "Arquivo de configuração do Zabbix Server encontrado"
else
    print_status 1 "Arquivo de configuração do Zabbix Server não encontrado"
    ((ERRORS++))
fi

# Verificar arquivo de configuração do Zabbix Agent
if [ -f "/etc/zabbix/zabbix_agentd.conf" ]; then
    print_status 0 "Arquivo de configuração do Zabbix Agent encontrado"
else
    print_status 1 "Arquivo de configuração do Zabbix Agent não encontrado"
    ((ERRORS++))
fi

echo ""
echo "5. Verificando interface web..."

# Verificar se o Apache está servindo o Zabbix
if curl -s -o /dev/null -w "%{http_code}" http://localhost/zabbix | grep -q "200\|302"; then
    print_status 0 "Interface web do Zabbix acessível"
else
    print_status 1 "Interface web do Zabbix não acessível"
    ((ERRORS++))
fi

# Verificar se o PHP está funcionando
if php -v > /dev/null 2>&1; then
    print_status 0 "PHP está instalado e funcionando"
else
    print_status 1 "PHP não está funcionando"
    ((ERRORS++))
fi

echo ""
echo "6. Verificando recursos do sistema..."

# Verificar uso de CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
if (( $(echo "$CPU_USAGE < 80" | bc -l) )); then
    print_status 0 "Uso de CPU OK ($CPU_USAGE%)"
else
    print_warning "Uso de CPU alto ($CPU_USAGE%)"
fi

# Verificar uso de memória
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ "$MEMORY_USAGE" -lt 80 ]; then
    print_status 0 "Uso de memória OK ($MEMORY_USAGE%)"
else
    print_warning "Uso de memória alto ($MEMORY_USAGE%)"
fi

# Verificar uso de disco
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    print_status 0 "Uso de disco OK ($DISK_USAGE%)"
else
    print_warning "Uso de disco alto ($DISK_USAGE%)"
fi

echo ""
echo "7. Verificando logs de erro..."

# Verificar logs do Zabbix Server
if [ -f "/var/log/zabbix/zabbix_server.log" ]; then
    ERROR_COUNT=$(grep -c "ERROR\|FATAL" /var/log/zabbix/zabbix_server.log 2>/dev/null || echo "0")
    if [ "$ERROR_COUNT" -eq 0 ]; then
        print_status 0 "Nenhum erro encontrado nos logs do Zabbix Server"
    else
        print_warning "$ERROR_COUNT erros encontrados nos logs do Zabbix Server"
    fi
else
    print_warning "Log do Zabbix Server não encontrado"
fi

# Verificar logs do Apache
if [ -f "/var/log/apache2/error.log" ]; then
    ERROR_COUNT=$(grep -c "ERROR\|FATAL" /var/log/apache2/error.log 2>/dev/null || echo "0")
    if [ "$ERROR_COUNT" -eq 0 ]; then
        print_status 0 "Nenhum erro encontrado nos logs do Apache"
    else
        print_warning "$ERROR_COUNT erros encontrados nos logs do Apache"
    fi
else
    print_warning "Log do Apache não encontrado"
fi

echo ""
echo "8. Verificando backup automático..."

# Verificar se o script de backup existe
if [ -f "/usr/local/bin/zabbix-backup.sh" ]; then
    print_status 0 "Script de backup encontrado"
else
    print_status 1 "Script de backup não encontrado"
    ((ERRORS++))
fi

# Verificar se o cron está configurado
if crontab -l 2>/dev/null | grep -q "zabbix-backup.sh"; then
    print_status 0 "Backup automático configurado no cron"
else
    print_status 1 "Backup automático não configurado no cron"
    ((ERRORS++))
fi

# Verificar diretório de backup
if [ -d "/var/backups/zabbix" ]; then
    print_status 0 "Diretório de backup existe"
else
    print_status 1 "Diretório de backup não existe"
    ((ERRORS++))
fi

echo ""
echo "=========================================="
echo "RESUMO DA VALIDAÇÃO"
echo "=========================================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Instalação do Zabbix validada com sucesso!${NC}"
    echo ""
    echo "Informações de acesso:"
    echo "- URL: http://$(curl -s ifconfig.me)/zabbix"
    echo "- Usuário: admin"
    echo "- Senha: [configurada em terraform.tfvars]"
    echo ""
    echo "Próximos passos recomendados:"
    echo "1. Alterar senhas padrão"
    echo "2. Configurar SSL/HTTPS"
    echo "3. Configurar hosts para monitoramento"
    echo "4. Configurar alertas e notificações"
    exit 0
else
    echo -e "${RED}✗ $ERRORS problemas encontrados na instalação${NC}"
    echo ""
    echo "Recomendações:"
    echo "1. Verificar logs de erro: /var/log/zabbix-install.log"
    echo "2. Reiniciar serviços: sudo systemctl restart zabbix-server zabbix-agent apache2"
    echo "3. Verificar configurações de banco de dados"
    echo "4. Executar novamente o script de instalação se necessário"
    exit 1
fi
