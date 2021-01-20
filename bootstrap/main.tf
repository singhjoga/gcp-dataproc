terraform {
  required_version = "~> 0.13"
}

provider "google" {
  version = ">= 3.50"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}

module "bootstrap" {
  source  = "terraform-google-modules/bootstrap/google"
  version = "~> 2.1"

  org_id               = "422558716844"
  billing_account      = "01EFE4-BA1C6D-9714BD"
  group_org_admins     = "gcp-organization-admins@thetechnovator.com"
  group_billing_admins = "gcp-billing-admins@thetechnovator.com"
  default_region       = "us-central1"
  folder_id			   = "584686646294"
}