# Outputs do projeto Zabbix

# Informações da instância
output "zabbix_instance_name" {
  description = "Nome da instância do Zabbix"
  value       = google_compute_instance.zabbix_server.name
}

output "zabbix_instance_id" {
  description = "ID da instância do Zabbix"
  value       = google_compute_instance.zabbix_server.instance_id
}

output "zabbix_instance_zone" {
  description = "Zona da instância do Zabbix"
  value       = google_compute_instance.zabbix_server.zone
}

# Informações de rede
output "zabbix_external_ip" {
  description = "IP externo do servidor Zabbix"
  value       = google_compute_address.zabbix_static_ip.address
}

output "zabbix_internal_ip" {
  description = "IP interno do servidor Zabbix"
  value       = google_compute_instance.zabbix_server.network_interface[0].network_ip
}

output "zabbix_network_name" {
  description = "Nome da rede VPC"
  value       = google_compute_network.zabbix_network.name
}

output "zabbix_subnet_name" {
  description = "Nome da subnet"
  value       = google_compute_subnetwork.zabbix_subnet.name
}

# URLs de acesso
output "zabbix_web_url" {
  description = "URL de acesso ao Zabbix Web Interface"
  value       = "http://${google_compute_address.zabbix_static_ip.address}/zabbix"
}

output "zabbix_web_url_https" {
  description = "URL HTTPS de acesso ao Zabbix Web Interface"
  value       = "https://${google_compute_address.zabbix_static_ip.address}/zabbix"
}

# Informações de SSH
output "ssh_connection_command" {
  description = "Comando para conectar via SSH"
  value       = "ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${google_compute_address.zabbix_static_ip.address}"
}

# Informações do banco de dados
output "zabbix_database_info" {
  description = "Informações do banco de dados"
  value = {
    type     = var.zabbix_db_type
    name     = var.zabbix_db_name
    user     = var.zabbix_db_user
    host     = "localhost"
    port     = var.zabbix_db_type == "mysql" ? 3306 : 5432
  }
  sensitive = false
}

# Informações de login do Zabbix
output "zabbix_login_info" {
  description = "Informações de login do Zabbix"
  value = {
    username = var.zabbix_admin_user
    url      = "http://${google_compute_address.zabbix_static_ip.address}/zabbix"
  }
  sensitive = true
}

# Informações do disco
output "zabbix_data_disk_name" {
  description = "Nome do disco de dados"
  value       = google_compute_disk.zabbix_data_disk.name
}

output "zabbix_data_disk_size" {
  description = "Tamanho do disco de dados em GB"
  value       = google_compute_disk.zabbix_data_disk.size
}

# Service Account
output "zabbix_service_account_email" {
  description = "Email do Service Account"
  value       = google_service_account.zabbix_service_account.email
}

# Informações de monitoramento
output "monitoring_alert_policy_name" {
  description = "Nome da política de alerta"
  value       = google_monitoring_alert_policy.zabbix_server_down.display_name
}

# Resumo da instalação
output "installation_summary" {
  description = "Resumo da instalação do Zabbix"
  value = {
    instance_name    = google_compute_instance.zabbix_server.name
    external_ip      = google_compute_address.zabbix_static_ip.address
    web_interface    = "http://${google_compute_address.zabbix_static_ip.address}/zabbix"
    ssh_command      = "ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${google_compute_address.zabbix_static_ip.address}"
    database_type    = var.zabbix_db_type
    zabbix_version   = var.zabbix_version
    machine_type     = var.machine_type
    data_disk_size   = "${var.data_disk_size}GB"
  }
}
