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

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = local.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = local.zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "f1-micro"
  }
}