variable "mytag" {
  type = "string"
}

resource "aws_vpc" "mainvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.mytag}"
  }
}

resource "aws_vpc" "secondvpc" {
  cidr_block = "10.2.0.0/16"

  tags = {
    Name = "secondVPC"
  }
}

resource "aws_instance" "db" {
  ami           = "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"
  user_data     = <<EOF
#!/bin/bash
sudo yum update
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Hello from Terraform</h1>" | sudo tee /var/www/html/index.html
EOF

  tags= {
    Name = "DB"
  }
}

output "DB Private IP" {
  value = "${aws_instance.db.private_ip}"
}

output "my_vpc_arn" {
  value = "${aws_vpc.mainvpc.arn}"
}

output "my_second_vpc_arn" {
  value = "${aws_vpc.secondvpc.arn}"
}

output "my_vpc_rt" {
  value = "${aws_vpc.mainvpc.main_route_table_id}"
}
