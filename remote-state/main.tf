resource "aws_s3_bucket" "s3backend" {
  bucket = "my-terraform-bucket-312"

  versioning {
    enabled = true
  }

  force_destroy = true
}

resource "aws_instance" "db" {
  ami           = "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"

  tags = {
    Name = "DB"
  }
}
