provider "aws" {
  region = "ap-south-1"  # Replace with your desired AWS region
}

# Security group to allow RDP access
resource "aws_security_group" "master" {
  vpc_id = "vpc-0a134c2c8adbdc400"

  # Allow SSH access (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow DCV access (port 8444)
  ingress {
    from_port   = 8444
    to_port     = 8444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate an SSH key pair
resource "tls_private_key" "master_key_gen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the Key Pair
resource "aws_key_pair" "master_key_pair" {
  key_name   = var.keypair_name
  public_key = tls_private_key.master_key_gen.public_key_openssh
}

# Windows Server instance with dynamic username and session setup
resource "aws_instance" "CentOS8-AMD" {
  ami               = "ami-0ad4e446a1a827dc7"  # Replace with your desired CentOS AMI ID
  instance_type     = "c6a.xlarge"            # Replace with your desired instance type
  key_name          = aws_key_pair.master_key_pair.key_name
  subnet_id         = "subnet-09c6010c6cbfd6a17"
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.master.id]

  # Updated user data script
 user_data = <<-EOF
    #!/bin/bash

    # Variables
    USER_NAME="${var.instance_name}"
    sudo systemctl restart sssd
    sudo su - $USER_NAME@sumedhalabs.com
    sudo dcv create-session --owner '$USER_NAME@sumedhalabs.com' SumedhaIT --type virtual
EOF
}

# Save the private key locally
resource "local_file" "local_key_pair" {
  filename        = "${var.instance_name}.pem"
  file_permission = "0400"
  content         = tls_private_key.master_key_gen.private_key_pem
}

# Output the CentOS8-AMD Server Public IP
output "CentOS8_AMD_Server_Private_IP" {
  value = aws_instance.CentOS8-AMD.public_ip
}

# Output the CentOS8-AMD Server private IP
output "CentOS8_AMD_Server_Public_IP" {
  value = aws_instance.CentOS8-AMD.private_ip
}

# Output the PEM file for SSH
output "pem_file_for_ssh" {
  value     = tls_private_key.master_key_gen.private_key_pem
  sensitive = true
}
