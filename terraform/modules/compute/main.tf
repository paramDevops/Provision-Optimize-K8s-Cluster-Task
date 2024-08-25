locals {
  commmon_tags = merge(var.additional_tags,
    {
      module_version = 1.0
  })
}

data "aws_caller_identity" "current" {}

# Create an S3 Bucket for static content 

resource "aws_s3_bucket" "static_content" {
  bucket = "${var.name}-content"
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.static_content.id

  index_document {
    suffix = "index.html"
  }
}

# Create Security Group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  vpc_id = var.vpc_id

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

# EC2 IAM role
resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.name}-iam-role"

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

# IAM Policy to allow S3 and SSM access
resource "aws_iam_policy" "s3_ssm_access_policy" {
  name        = "s3_ssm_access_policy"
  description = "Policy to allow S3 and SSM access for EC2 instances"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "ssm:DescribeInstanceInformation",
          "ssm:ListCommands",
          "ssm:SendCommand",
          "ssm:StartSession",
          "ssm:DescribeSessions",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = [
          "arn:aws:s3:::${var.name}-content",
          "arn:aws:s3:::${var.name}-content/*",
          "*"
        ]
      }
    ]
  })
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "ec2_iam_role_attachment" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = aws_iam_policy.s3_ssm_access_policy.arn
}

# Attach AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.name}_instance_profile"
  role = aws_iam_role.ec2_iam_role.name
}
# Create EC2 Instances
resource "aws_instance" "nginx_app" {
  count                       = 3
  ami                         = var.ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = element(var.frontend_subnet_ids, count.index)
  key_name                    = "test"
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true
  user_data                   = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              sudo apt update -y
              # Install ssm agent
              echo "Install SSM agent"
              sudo snap install amazon-ssm-agent --classic
              # start the SSM agent
              sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service
              sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
              sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
          
              echo "install nginx"
              sudo apt install -y nginx awscli
              sudo aws s3 cp s3://${aws_s3_bucket.static_content.bucket} /usr/share/nginx/html --recursive
              sudo systemctl start nginx
              EOF

  tags = merge(
    local.commmon_tags,
    {
      Name        = "${var.name}-${count.index}"
      name        = "${var.name}-${count.index}"
      description = "${var.name}-${count.index} ec2 instance"
  })
}

