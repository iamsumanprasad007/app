# EC2 Module - Main Configuration

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# S3 bucket for cluster setup coordination
resource "aws_s3_bucket" "k8s_setup" {
  bucket        = "${var.cluster_name}-k8s-setup-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "${var.cluster_name}-k8s-setup"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "k8s_setup" {
  bucket = aws_s3_bucket.k8s_setup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "k8s_setup" {
  bucket = aws_s3_bucket.k8s_setup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# IAM role for EC2 instances
resource "aws_iam_role" "k8s_node_role" {
  name = "${var.cluster_name}-k8s-node-role"

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

  tags = {
    Name        = "${var.cluster_name}-k8s-node-role"
    Environment = var.environment
  }
}

# IAM policy for Kubernetes nodes
resource "aws_iam_role_policy" "k8s_node_policy" {
  name = "${var.cluster_name}-k8s-node-policy"
  role = aws_iam_role.k8s_node_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:RevokeSecurityGroupIngress",
          "elasticloadbalancing:*",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.k8s_setup.arn,
          "${aws_s3_bucket.k8s_setup.arn}/*"
        ]
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "k8s_node_profile" {
  name = "${var.cluster_name}-k8s-node-profile"
  role = aws_iam_role.k8s_node_role.name

  tags = {
    Name        = "${var.cluster_name}-k8s-node-profile"
    Environment = var.environment
  }
}

# Master node
resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [var.master_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name

  user_data = templatefile("${path.module}/../../scripts/master-userdata.sh", {
    cluster_name = var.cluster_name
    aws_region   = var.aws_region
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name                                        = "${var.cluster_name}-master"
    Environment                                 = var.environment
    Type                                        = "master"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  depends_on = [aws_s3_bucket.k8s_setup]
}

# Worker nodes
resource "aws_instance" "worker" {
  count = var.worker_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [var.worker_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name

  user_data = templatefile("${path.module}/../../scripts/worker-userdata.sh", {
    cluster_name = var.cluster_name
    aws_region   = var.aws_region
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name                                        = "${var.cluster_name}-worker-${count.index + 1}"
    Environment                                 = var.environment
    Type                                        = "worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  depends_on = [aws_instance.master]
}
