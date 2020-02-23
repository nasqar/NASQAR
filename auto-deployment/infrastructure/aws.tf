provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
}

variable "prefix" {
  type = string
  default = "seurat-wizard"
}

variable "environment" {
  type = string
  default = "dev"
}

# variables not allowed here

terraform {
  backend "s3" {
    bucket = "seurat-wizard-terraform-state"
    key = "terraform/terraform-dev.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "seurat-wizard-terraform-state-lock"
  }
}
