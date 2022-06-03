
# DEPLOY A CLOUD RUN SERVICE

resource "google_cloud_run_service" "service" {
  name     = var.service_name
  location = var.location

  template {
    metadata {
      annotations = {
        "image" = var.image_name
        "repository" = var.repository_name == "" ? "-" : var.repository_name
        "autoscaling.knative.dev/maxScale" = "10"
        "run.googleapis.com/client-name" = "kubevela-terraform-controller"
      }
    }
    spec {
      containers {
        image = var.image_name

        dynamic "env" {
           for_each = var.env
           content {
              name = env.key
              value = env.value
           }
        }
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}



# EXPOSE THE SERVICE PUBLICALLY
# We give all users the ability to invoke the service.


resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.service.name
  location = google_cloud_run_service.service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}


