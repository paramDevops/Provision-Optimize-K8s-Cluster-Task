terraform {
  backend "s3" {
    bucket = "test2301-demo-tfstate-bucket"
    key    = "eks/terraform.tfstate"
    region = "us-west-2"
  }
}


