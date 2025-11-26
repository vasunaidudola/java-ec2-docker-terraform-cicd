terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "vasu-terraform-state-11262025"  # <-- change to your real bucket name
    key            = "ec2-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

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

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group to allow HTTP
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

# Amazon Linux 2 AMI
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instance
resource "aws_instance" "java_app" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Use templatefile and include deploy_version
  user_data = templatefile("${path.module}/user_data.sh", {
    dockerhub_username = var.dockerhub_username
    image_name         = var.image_name
    image_tag          = var.image_tag
    deploy_version     = var.deploy_version
  })

  # If user_data changes, replace instance (forces redeploy)
  user_data_replace_on_change = true

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "java-docker-ec2"
  }
}

# Output public IP
output "instance_public_ip" {
  value = aws_instance.java_app.public_ip
}
