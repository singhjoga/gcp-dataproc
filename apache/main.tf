terraform {
  required_version = "~> 0.13"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 3.53.0"
    }
  }
}
locals {
  region = "europe-west6"
  zone = "europe-west6-a"
  project_id="gke-learning-4caf"
  host_project_id="vpc-nonprod-4caf"
}

provider "google" {
	project	= local.project_id
	region	= local.region
	zone	= local.zone
}
data "google_compute_network" "shared_vpc" {
    name = "vpc-network"
    project = local.host_project_id
}
data "google_compute_address" "ip_address" {
  name = "static-ip"
}
data "google_compute_subnetwork" "shared_subnet" {
    name = "non-prod-private-us-central1"
    project = local.host_project_id
    region = local.region
}
resource "google_compute_instance" "instance_with_ip" {
  name         = "apache"
  machine_type = "f1-micro"
  zone         = local.zone
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  network_interface {
    network = data.google_compute_network.shared_vpc.id
    subnetwork = data.google_compute_subnetwork.shared_subnet.id
    access_config {
      nat_ip = "34.117.141.138" //data.google_compute_address.ip_address.address
    }
  }
}