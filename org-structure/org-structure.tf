terraform {
  required_version = "~> 0.13"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 3.51.1"
    }
  }
}
locals {
  region = "us-central1"
  zone = "us-central1-a"
}

provider "google" {
	project	= "data-proc-301511"
	region	= local.region
	zone	= local.zone
}

resource "google_folder" "non-prod" {
  display_name = "Non-Production"
  parent       = "organizations/422558716844"
}
resource "google_folder" "production" {
  display_name = "Production"
  parent       = "organizations/422558716844"
}
resource "google_folder" "non-prod-shared" {
  display_name = "Non-Production Shared"
  parent       = google_folder.non-prod.name
}
resource "google_folder" "learning" {
  display_name = "Learning"
  parent       = google_folder.non-prod.name
}

# Create non prod shared resources
resource "google_project" "host-non-prod" {
  name       = "Host-Non productiont"
  project_id = "host-non-prod"
  auto_create_network = false
  folder_id  = google_folder.non-prod-shared.name
#  billing_account = "01EFE4-BA1C6D-9714BD"
}

resource "google_project_service" "service" {
  for_each = toset([
    "compute.googleapis.com"
  ])

  service = each.key

  project            = google_project.host-non-prod.project_id
  disable_on_destroy = false
}


resource "google_compute_subnetwork" "non-prod-private-us-central1" {
  name          = "non-prod-private-us-central1"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.non-prod-network.id
}

resource "google_compute_network" "non-prod-network" {
  name = "vpc-network"
  auto_create_subnetworks = false
  project = google_project.host-non-prod.project_id
}