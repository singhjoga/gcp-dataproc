terraform {
  required_version = "~> 0.13"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 3.53.0"
    }
  }
}
/*
module "org" {
  source = "../org-structure"
  new_id = 1
}
*/
locals {
  region = "europe-west3"
  zone = "europe-west3-a"
  project_id="gke-learning-e4b0"
  host_project_id="vpc-nonprod-e4b0"
}

provider "google" {
	project	= local.project_id
	region	= local.region
	zone	= local.zone
}
provider "google-beta" {
	project	= local.project_id
	region	= local.region
	zone	= local.zone
}

data "google_compute_network" "shared_vpc" {
    name = "vpc-network"
    project = local.host_project_id
}

 
data "google_compute_subnetwork" "shared_subnet" {
    name = "non-prod-private-us-central1"
    project = local.project_id
    region = local.region
}
resource "google_container_cluster" "primary" {
  provider = "google-beta"
  name     = "my-gke-cluster"
  location = local.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  network = data.google_compute_network.shared_vpc.id
  subnetwork = data.google_compute_subnetwork.shared_subnet.id
  networking_mode = "VPC_NATIVE" # must for shared vpc
  ip_allocation_policy {
  	cluster_secondary_range_name="non-prod-private-us-central1-secondary"
  	services_secondary_range_name="non-prod-private-us-central1-secondary"
  }
}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = local.zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-standard-4"
  }
}