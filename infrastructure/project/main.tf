terraform {
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "1.4.0"
    }
  }

  cloud {
    organization = "oak-national-academy"
    workspaces {
      name = "kofo-test"
    }
  }
}


provider "vercel" {
  team = "kofoworolaogunleye-4134s-projects"
}


resource "vercel_project" "this" {
  name = "poc"

  git_repository = {
    type = "github"
    repo = "KofoworolaOgunleye/poc"
  }
  root_directory = "vercel-drift"
}

# resource "vercel_project_domain" "main" {
#   project_id = vercel_project.this.id
#   domain     = "hello-vercel-drift-test.vercel.app"
# }


# variable "vercel_team_id" {
#   type        = string
#   default     = null
#   description = "Team ID (optional)"
# }


