# Configuração do Provider Google Cloud Platform
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configuração do Provider GCP
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network para o Zabbix
resource "google_compute_network" "zabbix_network" {
  name                    = "${var.project_name}-network"
  auto_create_subnetworks = false
  description             = "Rede VPC para o servidor Zabbix"
}

# Subnet para o Zabbix
resource "google_compute_subnetwork" "zabbix_subnet" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.zabbix_network.id
  description   = "Subnet para o servidor Zabbix"
}

# Firewall para permitir tráfego HTTP/HTTPS e SSH
resource "google_compute_firewall" "zabbix_firewall" {
  name    = "${var.project_name}-firewall"
  network = google_compute_network.zabbix_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "10050", "10051"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["zabbix-server"]
  description   = "Regras de firewall para o servidor Zabbix"
}

# Endereço IP estático para o servidor Zabbix
resource "google_compute_address" "zabbix_static_ip" {
  name         = "${var.project_name}-static-ip"
  region       = var.region
  description  = "Endereço IP estático para o servidor Zabbix"
}

# Disco adicional para dados do Zabbix
resource "google_compute_disk" "zabbix_data_disk" {
  name  = "${var.project_name}-data-disk"
  type  = "pd-standard"
  zone  = var.zone
  size  = var.data_disk_size
  description = "Disco adicional para dados do Zabbix"
}

# Instância do servidor Zabbix
resource "google_compute_instance" "zabbix_server" {
  name         = "${var.project_name}-server"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["zabbix-server"]

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.boot_disk_size
      type  = "pd-standard"
    }
  }

  # Anexar disco de dados
  attached_disk {
    source      = google_compute_disk.zabbix_data_disk.id
    device_name = "zabbix-data"
  }

  network_interface {
    network    = google_compute_network.zabbix_network.id
    subnetwork = google_compute_subnetwork.zabbix_subnet.id
    access_config {
      nat_ip = google_compute_address.zabbix_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = templatefile("${path.module}/scripts/install-zabbix.sh", {
    zabbix_version = var.zabbix_version
    zabbix_db_type = var.zabbix_db_type
    zabbix_db_name = var.zabbix_db_name
    zabbix_db_user = var.zabbix_db_user
    zabbix_db_password = var.zabbix_db_password
    zabbix_admin_user = var.zabbix_admin_user
    zabbix_admin_password = var.zabbix_admin_password
    mysql_root_password = var.mysql_root_password
  })

  service_account {
    email  = google_service_account.zabbix_service_account.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_compute_disk.zabbix_data_disk,
    google_service_account.zabbix_service_account
  ]
}

# Service Account para o servidor Zabbix
resource "google_service_account" "zabbix_service_account" {
  account_id   = "${var.project_name}-sa"
  display_name = "Service Account para Zabbix Server"
  description  = "Service Account usado pelo servidor Zabbix"
}

# IAM binding para o service account
resource "google_project_iam_member" "zabbix_service_account_iam" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.zabbix_service_account.email}"
}

# Configuração de monitoramento básico
resource "google_monitoring_alert_policy" "zabbix_server_down" {
  display_name = "Zabbix Server Down"
  combiner     = "OR"
  conditions {
    display_name = "Zabbix Server Instance Down"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${google_compute_instance.zabbix_server.instance_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  notification_channels = var.notification_channels
  alert_strategy {
    auto_close = "1800s"
  }
}
