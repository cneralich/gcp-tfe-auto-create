provider "google" {
  credentials = "${var.gcp_credentials}"
}

resource "google_project" "new_project" {
  count = "${length(var.projects)}"
  name = "${element(var.projects, count.index)}"
  project_id = "${element(var.projects, count.index)}"
  org_id     = "${var.org_id}"
  billing_account = "${var.billing_account}"
}

resource "google_service_account" "project_admin" {
  count = "${length(var.projects)}"
  account_id   = "project-admin"
  display_name = "Project Admin"
  #project = "${google_project.new_project.number}"
  project = "${element(google_project.new_project.*.project_id, count.index)}"
}

/*resource "google_service_account_key" "mykey" {
  project = "${google_project.new_project.project_id}"
  count = "${length(var.projects)}"
  service_account_id = "${google_service_account.project_admin.name}"
}*/

resource "google_project_iam_member" "project" {
  count = "${length(var.projects)}"
  project = "${element(google_project.new_project.*.project_id, count.index)}"
  role    = "roles/editor"
  member  = "user:${var.iam_user_email}"
}

resource "google_project_service" "cloud_compute" {
  count = "${length(var.projects)}"
  project = "${element(google_project.new_project.*.project_id, count.index)}"
  service = "compute.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "billing" {
  count = "${length(var.projects)}"  
  project = "${element(google_project.new_project.*.project_id, count.index)}"
  service = "cloudbilling.googleapis.com"

  disable_dependent_services = true
}

provider "tfe" {
  version = "<= 0.7.0"
  token = "${var.token}"
}

resource "tfe_workspace" "main" {
  count = "${length(var.projects)}"
  name              = "${element(google_project.new_project.*.project_id, count.index)}"
  organization      = "${var.organization}"
  auto_apply        = "false"
  working_directory = "${element(var.directory, count.index)}"

  vcs_repo {
    identifier         = "${var.repo}"
    oauth_token_id     = "${var.oauth_token_id}"
  }
}

resource "tfe_variable" "tfvars_sensitive" {
  count = "${length(var.projects)}"
  key          = "gcp_credentials"
  value        = "${var.gcp_credentials}"
  category     = "terraform"
  sensitive    = true
  workspace_id = "${element(tfe_workspace.main.*.id, count.index)}"
}

resource "tfe_variable" "tfvars" {
  count = "${length(var.projects)}"
  key          = "gcp_project"
  value        = "${element(google_project.new_project.*.project_id, count.index)}"
  category     = "terraform"
  workspace_id = "${element(tfe_workspace.main.*.id, count.index)}"
}

resource "tfe_variable" "env_vars" {
  count        = "${length(var.projects)}"
  key          = "CONFIRM_DESTROY"
  value        = "1"
  category     = "env"
  workspace_id = "${element(tfe_workspace.main.*.id, count.index)}"
}
