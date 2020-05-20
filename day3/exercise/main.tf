module "ec2andsg" {
  source = "./ec2sg"
  ingress_list = [443,3306,22,23]
}
