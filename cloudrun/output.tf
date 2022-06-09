# Display the service URL
output "service_url" {
  description = "HTTP URL of the service"
  value = "${google_cloud_run_service.service.status[0].url}"
}


output "sa_name" {
  description = "The Service Account email"
  value = google_service_account.sa.email
}

# to base64 encode, set true
output "sa_private_key" {
  value = google_service_account_key.sa_key.private_key
  description = "The private key in JSON format"
  sensitive = false
}
