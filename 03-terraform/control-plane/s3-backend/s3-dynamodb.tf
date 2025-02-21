resource "aws_s3_bucket" "eks-s3" {
  bucket = "eks-control-plane-s3"
  force_destroy = true
  tags = {
    Name        = "robokart-eks-master-backend"
  }
}

resource "aws_dynamodb_table" "eks-table" {
  name           = "robokart-eks-master-backend"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "MsID"

  attribute {
    name = "MsID"
    type = "S"
  }
  
  tags = {
    Name        = "robokart-eks-master-backend"
  }
}