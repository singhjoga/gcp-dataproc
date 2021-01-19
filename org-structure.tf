terraform {
  required_version = "~> 0.11"
  required_providers {
    google = {
      version = "~>= 3.0.0-beta.1"
      source = "hashicorp/google"
    }
  }
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