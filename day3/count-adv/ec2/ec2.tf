variable "servers" {
  type = "list"
}

resource "aws_instance" "ec2" {
  ami           = "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"
  count         = "${length(var.servers)}"

  tags = {
    Name = "${var.servers[count.index]}"
  }
}
