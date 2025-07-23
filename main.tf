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

  # Allow DCV access (port 8443)
  ingress {
    from_port   = 8443
    to_port     = 8443
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

  tags = {
    Name = "${var.instance_name}-${var.suffix}-SG"
  }
}

# Generate an SSH key pair
resource "tls_private_key" "master_key_gen" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create the Key Pair
resource "aws_key_pair" "master_key_pair" {
  key_name   = "${var.instance_name}-${var.name}-${var.suffix}.pem"
  public_key = tls_private_key.master_key_gen.public_key_openssh
}

# Windows Server instance with dynamic username and session setup
resource "aws_instance" "CentOS8-AMD" {
  ami               = "ami-09aff23a6e4129518"  # Replace with your desired CentOS AMI ID
  instance_type     = var.instance_type            # Replace with your desired instance type
  key_name          = aws_key_pair.master_key_pair.key_name
  subnet_id         = "subnet-09c6010c6cbfd6a17"
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.master.id]
  iam_instance_profile = "SSM"

  # Updated user data script
  user_data = <<-EOF
    #!/bin/bash

    # Variables
    sudo -i
    original_var="${var.instance_name}"
    USER_NAME=$(echo "$original_var" | sed 's/_[[:space:]]/  /g' | sed 's/_$//')
    systemctl restart sssd
    su - $USER_NAME@sumedhalabs.com
    #sudo dcv create-session --owner '$USER_NAME@sumedhalabs.com' SumedhaIT --type virtual
    /usr/bin/sudo /usr/bin/dcv create-session 'SumedhaIT-$USER_NAME' --owner $USER_NAME@sumedhalabs.com --type virtual >> /var/log/dcv-session.log 2>&1
  EOF
  tags = {
    Name = "${var.instance_name}-${var.name}-${var.suffix}"
  }
}

# Save the private key locally
resource "local_file" "local_key_pair" {
  filename        = "${var.instance_name}-${var.name}-${var.suffix}.pem"
  file_permission = "0400"
  content         = tls_private_key.master_key_gen.private_key_pem
}

# Output the CentOS8-AMD Server Public IP
output "CentOS8_AMD_Server_Public_IP" {
  value = aws_instance.CentOS8-AMD.public_ip
}

# Output Copy the URL
output "CentOS8_AMD_Login" {
  value = "Copy the mentioned URL & Paste it on Browser https://${aws_instance.CentOS8-AMD.public_ip}:8443"
}
 # Output the PEM file for SSH
output "pem_file_for_ssh" {
  value     = tls_private_key.master_key_gen.private_key_pem
  sensitive = true
 }
