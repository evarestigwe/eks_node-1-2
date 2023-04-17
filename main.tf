terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
      ##### Adding parameters
    }
  }

  required_version = ">= 0.13"
}

provider "aws" {
  region = "us-east-1" # Change this to your preferred region"
  shared_config_files = ["%USERPROFILE%/.aws/config"]
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "kubernetes" {
  ami           = data.aws_ami.amazon_linux.id # Amazon Linux 2
  instance_type = "t2.micro"
  count = 3
  key_name      = "terra"
  vpc_security_group_ids = [aws_security_group.allow_web_kubernetes.id]
  user_data = data.template_file.startup.rendered
  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = 20
  }

  tags = {
              Name = "kubernetes"
         }

}


data "template_file" "startup" {
  template = file("script.sh")
}

resource "aws_security_group" "allow_web_kubernetes" {
  name        = "security_group_for_services_ec2_kubernetes"
  description = "Allows access to Web Port"

  #allow http

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["197.210.84.77/32"]
  }

  # allow https

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["197.210.84.77/32"]
  }

  # allow SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["197.210.84.77/32"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "all"
    cidr_blocks = ["197.210.84.77/32"]
  }


  #all outbound

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Owner = "487352622603 "
  }
  lifecycle {
    create_before_destroy = true
  }

}
