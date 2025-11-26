terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "web_sg" {
  name        = "java-docker-ec2-sg"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "java_app" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet_ids.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    dockerhub_username = var.dockerhub_username
    image_name         = var.image_name
    image_tag          = var.image_tag
  })

  tags = {
    Name = "java-docker-ec2"
  }
}

output "instance_public_ip" {
  value = aws_instance.java_app.public_ip
}
