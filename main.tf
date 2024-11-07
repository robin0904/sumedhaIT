provider "aws" {
  region = "ap-south-1"  # Replace with your desired AWS region
}

# Security group to allow RDP access
resource "aws_security_group" "master" {
  vpc_id = "vpc-0a134c2c8adbdc400"

  # Allow RDP access (port 3389)
  ingress {
    from_port   = 3389
    to_port     = 3389
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

# Windows Server instance with dynamic password and variable username
resource "aws_instance" "CentOS8-AMD" {
  ami               = "ami-00b84670be6b17d8e"  # Replace with your desired Windows AMI ID
  instance_type     = "c6a.xlarge"  # Replace with your desired instance type
  key_name          = aws_key_pair.master_key_pair.key_name
  subnet_id         = "subnet-01e7e581424a68b10"
  availability_zone = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.master.id]

  # Corrected user data for PowerShell execution
  user_data = <<-EOF
    #!/bin/bash
    sudo dcv create-session --owner 'Sumedha@sumedhait.com' SumedhaIT --type virtual
    EOF

  tags = {
    Name = var.instance_name
  }
}

# Save the private key locally
resource "local_file" "local_key_pair" {
  filename        = "${var.keypair_name}.pem"
  file_permission = "0400"
  content         = tls_private_key.master_key_gen.private_key_pem
}

# Output the CentOS8-AMD Server private IP
output "CentOS8_AMD_Server_IP" {
  value = aws_instance.CentOS8-AMD.private_ip
}
