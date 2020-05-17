variable "ec2tagvalue" {
  type = "string"
}

variable "ec2ami" {
  type = "string"
}

resource "aws_instance" "db" {
  ami           = "${var.ec2ami}"
  instance_type = "t2.micro"

  tags = {
    Name = "${var.ec2tagvalue}"
  }
}
