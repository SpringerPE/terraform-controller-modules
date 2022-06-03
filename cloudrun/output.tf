# Display the service URL
output "service_url" {
  description = "HTTP URL of the service"
  value = "${google_cloud_run_service.service.status[0].url}"
}

