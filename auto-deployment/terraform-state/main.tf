variable "prefix" {
  type = string
  default = "seurat-wizard"
}

data "aws_region" "current" {}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}


resource "aws_s3_bucket" "terraform-state" {
  bucket = "${var.prefix}-terraform-state"
  acl = "private"
  region = data.aws_region.current.name

  versioning {
    enabled = true
  }

  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}

resource "aws_dynamodb_table" "terraform-state-lock" {
  name = "${var.prefix}-terraform-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
