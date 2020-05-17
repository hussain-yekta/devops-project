module "ec2module" {
  source = "./ec2"
  ec2tagvalue = "Web"
  ec2ami = "ami-0323c3dd2da7fb37d"
}

module "vpcmodule" {
  source = "./vpc"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "1.72.0"

  name = "my-vpc"
  cidr = "10.89.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.89.1.0/24", "10.89.2.0/24", "10.89.3.0/24"]
  public_subnets  = ["10.89.101.0/24", "10.89.102.0/24", "10.89.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
