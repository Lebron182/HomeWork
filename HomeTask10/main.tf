variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}
variable "private_key_path" {}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}
resource "aws_vpc" "tmg_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_internet_gateway" "tmg_gateway" {
  vpc_id = aws_vpc.tmg_vpc.id
}

resource "aws_route_table" "tmg_route_table" {
  vpc_id = aws_vpc.tmg_vpc.id

  route  {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.tmg_gateway.id
    }
}

resource "aws_subnet" "tmg_subnet" {
  vpc_id     = aws_vpc.tmg_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tmg_subnet.id
  route_table_id = aws_route_table.tmg_route_table.id
}

resource "aws_security_group" "tmg_allow_tls" {
  name        = "allow_web"
  description = "Allow TLS inbound web traffic(22/80/443 tcp)"
  vpc_id      = aws_vpc.tmg_vpc.id

  ingress {
      description      = "https to VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
      description      = "http to VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
      description      = "ssh to VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["45.151.236.24/32"]
      ipv6_cidr_blocks = ["::/0"]
  }
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_network_interface" "tmg_netinterface" {
  subnet_id       = aws_subnet.tmg_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.tmg_allow_tls.id]
}

resource "aws_eip" "tmg_elastic_ip" {
  vpc = true
  network_interface = aws_network_interface.tmg_netinterface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.tmg_gateway]
}

resource "aws_instance" "tmg_webserver" {
  ami               = "ami-00399ec92321828f5"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "main_key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.tmg_netinterface.id
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo Hi everyone > /var/www/html/index.html'
              EOF
  tags = {
    Name = "TMG_WebServer"
  }   
}
