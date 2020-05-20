module "ec2" {
  source = "./ec2"
  servers = ["web", "db", "app", "bastion", "jackpot"]
}
