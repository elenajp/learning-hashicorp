provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70.0"
    }
    vault = {
      source = "enter_source_here"
    }
  }

  required_version = ">= 0.14.9"
}

provider "vault" {
  address = "http://localhost:8200"
}
