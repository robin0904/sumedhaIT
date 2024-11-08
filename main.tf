provider "aws" {
  region = "ap-south-1"  # Replace with your desired AWS region
}

# Security group to allow necessary access
resource "aws_security_group" "master" {
  vpc_id = "vpc-0a134c2c8adbdc400"

  # Allow SSH access (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow application access (port 8444)
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

# IAM Role and Policy for SSM Domain Join
resource "aws_iam_role" "ssm_role" {
  name = "SSMRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ssm_managed_instance" {
  name       = "attach-ssm-policy"
  roles      = [aws_iam_role.ssm_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

# EC2 Instance with Domain Join to AWS Managed Microsoft AD
resource "aws_instance" "CentOS8-AMD" {
  ami               = "ami-00b84670be6b17d8e"  # Replace with your desired Windows AMI ID
  instance_type     = "c6a.xlarge"  # Replace with your desired instance type
  key_name          = aws_key_pair.master_key_pair.key_name
  subnet_id         = "subnet-01e7e581424a68b10"
  availability_zone = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.master.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name  # Attach the IAM role for SSM

  tags = {
    Name = var.instance_name
  }
}

# SSM Association for AWS Managed Microsoft AD Domain Join
resource "aws_ssm_association" "domain_join" {
  name = "AWS-JoinDirectoryServiceDomain"

  # Using targets instead of instance_id
  targets{
      key    = "InstanceIds"
      values = [aws_instance.CentOS8-AMD.id]
    }

  parameters = {
    directoryId = "d-9f6773508e"  # ID of your AWS Managed Microsoft AD
  }
}


# Save the private key locally
resource "local_file" "local_key_pair" {
  filename        = "${var.keypair_name}.pem"
  file_permission = "0400"
  content         = tls_private_key.master_key_gen.private_key_pem
}

# Outputs
output "CentOS8_AMD_Server_IP" {
  value = aws_instance.CentOS8-AMD.private_ip
}

output "pem_file_for_ssh" {
  value     = tls_private_key.master_key_gen.private_key_pem
  sensitive = true
}
