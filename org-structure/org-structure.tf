terraform {
  required_version = "~> 0.13"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 3.0.0"
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
resource "google_folder" "shared" {
  display_name = "Shared"
  parent       = google_folder.non-prod.name
}
resource "google_folder" "learning" {
  display_name = "Learning"
  parent       = google_folder.non-prod.name
}