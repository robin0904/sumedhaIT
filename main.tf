provider "aws" {
  region = "ap-south-1"
}

# Data source for the existing Directory Service
data "aws_directory_service_directory" "existing" {
  directory_id = var.directory_id
}

# IAM role for EC2 to use SSM
resource "aws_iam_role" "ssm_role" {
  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required policies for SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMMangedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# Your existing security group configuration
resource "aws_security_group" "master" {
  vpc_id = "vpc-0a134c2c8adbdc400"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8444
    to_port     = 8444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "tls_private_key" "master_key_gen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "master_key_pair" {
  key_name   = var.keypair_name
  public_key = tls_private_key.master_key_gen.public_key_openssh
}

# SSM association to join the domain
resource "aws_ssm_association" "domain_join" {
  name = "AWS-JoinDirectoryServiceDomain"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.CentOS8-AMD.id]
  }

  parameters = {
    directoryId = data.aws_directory_service_directory.existing.id
    directoryName = data.aws_directory_service_directory.existing.name
  }
}

# EC2 instance
resource "aws_instance" "CentOS8-AMD" {
  ami               = "ami-00b84670be6b17d8e"
  instance_type     = "c6a.xlarge"
  key_name          = aws_key_pair.master_key_pair.key_name
  subnet_id         = "subnet-01e7e581424a68b10"
  availability_zone = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.master.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    sudo dcv create-session --owner 'admin@sumedhait.com' SumedhaIT --type virtual
    EOF

  tags = {
    Name = var.instance_name
  }
}

resource "local_file" "local_key_pair" {
  filename        = "${var.keypair_name}.pem"
  file_permission = "0400"
  content         = tls_private_key.master_key_gen.private_key_pem
}

output "CentOS8_AMD_Server_IP" {
  value = aws_instance.CentOS8-AMD.private_ip
}

output "pem_file_for_ssh" {
  value = tls_private_key.master_key_gen.private_key_pem
  sensitive = true
}
