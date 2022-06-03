variable "project" {
  description = "The project ID where all resources will be launched."
  type = string
}

variable "service_name" {
  description = "The name of the Cloud Run service to deploy."
  type = string
}

variable "repository_name" {
  description = "The name of the git repository."
  type = string
  default = ""
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

variable "location" {
  description = "The location (region or zone) to deploy the Cloud Run services. Note: Be sure to pick a region that supports Cloud Run."
  type = string
  default = "europe-west4"
}

variable "region" {
  description = "Name of the GCP region where the GCR registry is located. e.g: 'us' or 'eu'."
  type = string
  default = "eu"
}



