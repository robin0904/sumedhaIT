provider "aws" {
  region = "ap-south-1" # Replace with your desired AWS region
  # profile = "Sumedha"
}

# Importing the SG
data "aws_security_group" "TerraformSecurityGroup" {
  id = "sg-04430765f75fb1634"
  # name = "Terraform-Servers-SG"
}

# Generate an SSH key pair
resource "tls_private_key" "master_key_gen" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create the Key Pair
resource "aws_key_pair" "master_key_pair" {
  key_name   = "${var.name}-${var.instance_name}-${var.suffix}"
  public_key = tls_private_key.master_key_gen.public_key_openssh
}

# Windows Server instance with dynamic username and session setup
resource "aws_instance" "CentOS8-AMD" {
  ami                    = "ami-0e21c1d2051dcf1d1" # Replace with your desired CentOS AMI ID
  instance_type          = var.instance_type       # Replace with your desired instance type
  key_name               = aws_key_pair.master_key_pair.key_name
  subnet_id              = "subnet-01e7e581424a68b10"
  availability_zone      = "ap-south-1a"
  vpc_security_group_ids = [data.aws_security_group.TerraformSecurityGroup.id]
  iam_instance_profile   = "SSM"

  # Updated user data script
  user_data = <<-EOF
    #!/bin/bash

    sed -i 's/^PasswordAuthentication no$/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd

    ########
    # Variables
    # original_var="${var.instance_name}"
    # USER_NAME=$(echo "$original_var" | sed 's/_[[:space:]]/  /g' | sed 's/_$//')
    # systemctl restart sssd
    # su - $USER_NAME@sumedhalabs.com
    # #sudo dcv create-session --owner '$USER_NAME@sumedhalabs.com' SumedhaIT --type virtual
    # /usr/bin/sudo /usr/bin/dcv create-session 'SumedhaIT-$USER_NAME' --owner $USER_NAME@sumedhalabs.com --type virtual >> /var/log/dcv-session.log 2>&1
    # sudo semanage fcontext -a -t ssh_home_t '/home/[^/]+/.ssh(/.*)?'
    # sudo restorecon -R -v /home/cloud-user/.ssh/
    # sudo restorecon -R -v /home/cloud-user/.ssh/    
    #########
  EOF
  tags = {
    Name = "${var.name}-${var.instance_name}-${var.suffix}"
  }
}

# Save the private key locally
resource "local_file" "local_key_pair" {
  filename        = "${var.name}-${var.instance_name}-${var.suffix}.pem"
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
  value     = aws_key_pair.master_key_pair.key_name
  sensitive = true
}
