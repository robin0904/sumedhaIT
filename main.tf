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

  tags = {
    Name = "${var.instance_name}-SG"
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
  ami               = "ami-0e51044ae4e4e5ef5"  # Replace with your desired CentOS AMI ID
  instance_type     = "c6a.xlarge"            # Replace with your desired instance type
  key_name          = aws_key_pair.master_key_pair.key_name
  subnet_id         = "subnet-09c6010c6cbfd6a17"
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.master.id]

  # Updated user data script
  user_data = <<-EOF
    #!/bin/bash

    # Variables
    DCV_SESSION_NAME="SumedhaIT"
    USER_NAME="${var.instance_name}"

    # Check if user exists
    if id "$USER_NAME" &>/dev/null; then
        echo "User $USER_NAME exists."
    else
        echo "User $USER_NAME does not exist. Creating user..."
        sudo useradd -m "$USER_NAME"    # Create user with a home directory
        echo "$USER_NAME:password" | sudo chpasswd # Set default password, change as required
        echo "User $USER_NAME created."
    fi

    # Start the NICE DCV session
    echo "Starting NICE DCV session..."
    sudo dcv create-session --owner "$USER_NAME"@sumedhait.com --type virtual

    # Verify session creation
    if dcv list-sessions | grep -q "$DCV_SESSION_NAME"; then
        echo "NICE DCV session $DCV_SESSION_NAME created successfully."
    else
        echo "Failed to create NICE DCV session $DCV_SESSION_NAME."
        exit 1
    fi
  EOF

  tags = {
    Name = "${var.instance_name}-SumedhaIT-server"
  }
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

