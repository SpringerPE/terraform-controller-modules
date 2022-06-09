# GENERATE RANDOM ID

resource "random_id" "uniq" {
  byte_length = 4
  keepers = {
    service_name = var.service_name
  }
}


# GENERATE SA

resource "google_service_account" "sa" {
  project      = var.project
  account_id   = "sa-${var.service_name}-${random_id.uniq.hex}"
  display_name = "sa-${var.service_name}-${random_id.uniq.hex}"
}


resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.sa.name
}

