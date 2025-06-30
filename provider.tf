/*
terraform {
  required_providers {
    mock = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
  }
}
*/

provider "null" {}

resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "echo 'This is a mock provider resource for testing purposes.'"
  }
}
