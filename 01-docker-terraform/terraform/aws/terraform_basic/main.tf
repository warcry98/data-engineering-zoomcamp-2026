terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.20, <= 5.29"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.8"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --------------------------------------------------
# Auto-fetch AWS Account ID (project_id equivalent)
# --------------------------------------------------
data "aws_caller_identity" "current" {}

# --------------------------------------------------
# Random suffix for global uniqueness
# --------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 2
}

# --------------------------------------------------
# S3 Data Lake Bucket
# --------------------------------------------------
resource "aws_s3_bucket" "data_lake_bucket" {
  bucket        = "datalake-myproject-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# --------------------------------------------------
# Enable versioning
# --------------------------------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --------------------------------------------------
# Block public access (best practice)
# --------------------------------------------------
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------
# Lifecycle rule: delete objects after 30 days
# --------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  rule {
    id     = "delete-after-30-days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# --------------------------------------------------
# Athena Database (BigQuery Dataset equivalent)
# --------------------------------------------------
resource "aws_glue_catalog_database" "athena_db" {
  name = "athena_myproject_${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
}