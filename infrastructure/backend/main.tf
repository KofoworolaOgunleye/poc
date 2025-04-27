data "terraform_remote_state" "google_project" {
  backend = "remote"
  config = {
    organization = "oak-national-academy"
    workspaces = {
      name = "curr-kofo"
    }
  }
}

variable "tag_id" {
  description = "Git tag used as a version identifier"
  type        = string
}


provider "google" {
  project = "oak-sandbox-wif-bucket"
  region  = "europe-west2"
}

resource "google_storage_bucket" "example" {
  name     = "my-appq"
  location = "europe-west1"
  force_destroy = true

  versioning {
    enabled = false
  }

}
#test
output "bucket_name" {
  value = google_storage_bucket.example.name
}