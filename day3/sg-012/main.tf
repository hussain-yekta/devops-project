variable "ingress_ports_list" {
  type = list(number)
  default = [80,443,3306]
}

variable "egress_ports_list" {
  type = list(number)
  default = [80,443,3306]
}

resource "aws_instance" "ec2" {
  ami             = "ami-0323c3dd2da7fb37d"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]

  tags = {
    Name = "SG EC2"
  }
}

resource "aws_security_group" "web_traffic" {
  name = "Allow HTTPS"

  dynamic "ingress" {
    iterator    = portnumber
    for_each    = var.ingress_ports_list
    content {
    from_port   = portnumber.value
    to_port     = portnumber.value
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    iterator    = portnumber
    for_each    = var.ingress_ports_list
    content {
    from_port   = portnumber.value
    to_port     = portnumber.value
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }
}


output "current_rules" {
  value = aws_security_group.web_traffic[*].ingress
}

output "expected" {
  value = [ for port in var.ingress_ports_list : "Port ${port} expected to be open"]
}
