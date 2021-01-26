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

data "google_compute_address" "ip_address" {
  name = "static-ip"
}

resource "google_compute_instance" "instance_with_ip" {
  name         = "apache"
  machine_type = "f1-micro"
  zone         = "europe-west6-a"


  network_interface {
    network = "default"
    access_config {
      nat_ip = data.google_compute_address.ip_address.address
    }
  }
}