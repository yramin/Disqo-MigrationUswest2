terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = ">= 2.19.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.25"
    }
  }
  required_version = ">= 0.13"
}
