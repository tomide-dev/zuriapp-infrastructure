#==================================
#GET LATEST UBUNTU AMI
#==================================
data "aws_ami" "ubuntu" {
most_recent = true

owners = ["099720109477"]

filter {
name = "name"
values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
}

filter {
name = "architecture"
values = ["x86_64"]
}

filter {
name = "virtualization-type"
values = ["hvm"]
}
}

# ===================================
# SECURITY GROUP
# ===================================

resource "aws_security_group" "zuriapp_sg" {
  name        = "zuriapp-security-group"
  description = "Allow SSH, HTTP, HTTPS, Kubernetes"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Terraform"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
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
    Name = "zuriapp-security-group"
  }
}


# ===================================
# IAM ROLE
# ===================================

resource "aws_iam_role" "ec2_role" {
  name = "zuriapp-ec2-role"

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


# ===================================
# IAM POLICY ATTACHMENT
# ===================================

resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}


# ===================================
# IAM INSTANCE PROFILE
# ===================================

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "zuriapp-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


# ===================================
# EC2 INSTANCE
# ===================================

resource "aws_instance" "zuriapp_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.zuriapp_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }
}