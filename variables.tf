variable "token" {}

variable "oauth_token_id" {}

variable "repo" {}

variable "org_id" {}

variable "billing_account" {}

variable "iam_user_email" {}

variable "organization" {}

variable "projects" {
  type        = "list"
  default     = []
}

variable "directory" {
    type = "list"
    default = []
}

variable "gcp_credentials" {}
