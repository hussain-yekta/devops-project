terraform {
  backend "s3" {
    bucket = "my-terraform-bucket-312"
    key    = "terraform/tfstate.tfstate"
    region = "us-east-1"
  }
}
