terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.11"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
}


variable "project" {
  description = "The project ID where all resources will be launched."
  type = string
}

variable "service_name" {
  description = "The name of the Cloud Run service to deploy."
  type = string
}

variable "image_name" {
  description = "The name of the image to deploy. Defaults to a publically available image."
  type = string
  default = "gcr.io/cloudrun/hello"
}

variable "env" {
  description = "Map key:value of environment variables"
  type = map(any)
}



module "cloudrun" {
  source                  = "../cloudrun"
  project                 = var.project
  service_name            = var.service_name
  env                     = var.env
  image_name              = var.image_name
}



# Display the service URL
output "service_url" {
  description = "HTTP URL of the service"
  value = "${module.cloudrun.service_url}"
}


output "repository_http_url" {
  description = "HTTP URL of the repository in Cloud Source Repositories."
  value = "${module.cloudrun.repository_http_url}"
}



