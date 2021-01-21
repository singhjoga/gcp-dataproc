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
  region = "us-central1"
  zone = "us-central1-a"
  project_id="gke-learning-8abf"
}

provider "google" {
	project	= local.project_id
	region	= local.region
	zone	= local.zone
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = local.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  network = "projects/vpc-nonprod-8abf/global/networks/vpc-network"
}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = local.zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "f1-micro"
  }
}