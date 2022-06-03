terraform {
  required_version = ">= 0.14"

  required_providers {
    # Cloud Run support was added on 3.3.0
    google = ">= 3.3"
  }
}

# Configure GCP project
provider "google" {
  project = var.project
}


# Enable Cloud Run API
#resource "google_project_service" "run" {
#  service = "run.googleapis.com"
#  disable_on_destroy = true
#}

