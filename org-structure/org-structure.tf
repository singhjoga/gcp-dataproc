terraform {
  required_version = "~> 0.13"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 3.53.0"
    }
  }
}
provider "random" {
  version = "~> 2.2"
}
variable "new_id" {
  type = string
}
resource "random_id" "random_project_id_suffix" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    ami_id = "${var.new_id}"
  }
  byte_length = 2
}
locals {
  region = "europe-west3"
  zone = "europe-west3-a"
  vpc_project_id = format("%s-%s","vpc-nonprod",random_id.random_project_id_suffix.hex)
  gke_project_id = format("%s-%s","gke-learning",random_id.random_project_id_suffix.hex)
}

provider "google" {
	project	= local.vpc_project_id
	region	= local.region
	zone	= local.zone
}
resource "google_folder" "admin" {
  display_name = "OrgAdmin"
  parent       = "organizations/422558716844"
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
resource "google_project" "vpc-nonprod" {
  name       = "VPC Non-Production"
  project_id = local.vpc_project_id
#  auto_create_network = false
  folder_id  = google_folder.non-prod-shared.id
  billing_account = "01EFE4-BA1C6D-9714BD"
}

resource "google_project_service" "service" {
  for_each = toset([
  	"compute.googleapis.com","container.googleapis.com"
  ])
  service			 = each.key
  project            = google_project.vpc-nonprod.project_id
  disable_on_destroy = false
}


resource "google_compute_subnetwork" "non-prod-private-us-central1" {
  name          = "non-prod-private-us-central1"
  ip_cidr_range = "10.2.0.0/16"
  region        = local.region
  network       = google_compute_network.non-prod-network.id
  secondary_ip_range {
    range_name    = "non-prod-private-us-central1-secondary"
    ip_cidr_range = "192.168.0.0/16"  #big range is important
  }
}

resource "google_compute_network" "non-prod-network" {
  name = "vpc-network"
  auto_create_subnetworks = false
  project = google_project.vpc-nonprod.project_id
}

resource "google_project" "gke-learning" {
  name       = "GKE Learning"
  project_id = local.gke_project_id
#  auto_create_network = false
  folder_id  = google_folder.learning.id
  billing_account = "01EFE4-BA1C6D-9714BD"
}

resource "google_project_service" "service-1" {
  for_each = toset([
  	"compute.googleapis.com","container.googleapis.com"
  ])
  service			 = each.key
  project            = google_project.gke-learning.project_id
  disable_on_destroy = false
}

resource "google_compute_shared_vpc_host_project" "shared-vpc-host" {
  project = google_project.vpc-nonprod.project_id
}

resource "google_compute_shared_vpc_service_project" "service1" {
  host_project    = google_compute_shared_vpc_host_project.shared-vpc-host.project
  service_project = google_project.gke-learning.project_id
}

output "vpc_host_project_id" {
	value = google_project.vpc-nonprod.project_id
}
output "gke_learning_project_id" {
	value = google_project.gke-learning.project_id
}

# assign roles to the service accounts for gke

resource "google_project_iam_member" "member-1" {
  project = google_project.gke-learning.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_project.gke-learning.number}@cloudservices.gserviceaccount.com"
}
resource "google_project_iam_member" "member-2" {
  project = google_project.gke-learning.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${google_project.gke-learning.number}@container-engine-robot.iam.gserviceaccount.com"
}

# GKE Service Agent on host project
resource "google_project_iam_member" "member-3" {
  project = google_project.vpc-nonprod.project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${google_project.gke-learning.number}@container-engine-robot.iam.gserviceaccount.com"
}
resource "google_project_iam_member" "member-4" {
  project = google_project.vpc-nonprod.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${google_project.gke-learning.number}@container-engine-robot.iam.gserviceaccount.com"
}

/*
resource "google_project_iam_member" "project" {
  for_each = toset([
  	"serviceAccount:${google_project.gke-learning.number}@cloudservices.gserviceaccount.com",
  	"serviceAccount:service-${google_project.gke-learning.number}@container-engine-robot.iam.gserviceaccount.com"
  ])
  project = google_project.gke-learning.project_id
  role    = "roles/compute.networkUser"
  member  = each.key
  
  depends_on = [
  	google_project.gke-learning
  ]
}
*/
