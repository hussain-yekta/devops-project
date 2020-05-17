resource "aws_instance" "db" {
  ami           = "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"

  tags = {
    Name = "DB"
  }
}
