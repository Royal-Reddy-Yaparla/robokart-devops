terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.82.2"
    }
  }
  # backend "s3" {
  #   bucket = "robokart-eks-master-backend"
  #   key    = "MsID"
  #   region = "us-east-1"
  # }
}

provider "aws" {
   region = "us-east-1"
}