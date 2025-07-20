# Main Terraform Configuration for Dev Environment

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TopList-K8s"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Local values
locals {
  cluster_name = "${var.cluster_name}-${var.environment}"
  
  common_tags = {
    Project     = "TopList-K8s"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = local.cluster_name
  environment          = var.environment
  aws_region           = var.aws_region
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id          = module.vpc.vpc_id
  vpc_cidr_block  = module.vpc.vpc_cidr_block
  cluster_name    = local.cluster_name
  environment     = var.environment
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  cluster_name              = local.cluster_name
  environment               = var.environment
  aws_region                = var.aws_region
  key_name                  = var.key_name
  master_instance_type      = var.master_instance_type
  worker_instance_type      = var.worker_instance_type
  worker_count              = var.worker_count
  public_subnet_ids         = module.vpc.public_subnet_ids
  master_security_group_id  = module.security_groups.master_security_group_id
  worker_security_group_id  = module.security_groups.worker_security_group_id
}

# Application Load Balancer for Ingress
resource "aws_lb" "ingress" {
  name               = "${local.cluster_name}-ingress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security_groups.alb_security_group_id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-ingress-alb"
  })
}

# Target Group for Worker Nodes
resource "aws_lb_target_group" "workers" {
  name     = "${local.cluster_name}-workers-tg"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-workers-tg"
  })
}

# Target Group Attachment for Worker Nodes
resource "aws_lb_target_group_attachment" "workers" {
  count = var.worker_count

  target_group_arn = aws_lb_target_group.workers.arn
  target_id        = module.ec2.worker_instance_ids[count.index]
  port             = 30080
}

# ALB Listener
resource "aws_lb_listener" "ingress" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.workers.arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-ingress-listener"
  })
}

# Route53 Hosted Zone (Optional)
resource "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  
  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-zone"
  })
}

# Route53 Record for ALB (Optional)
resource "aws_route53_record" "app" {
  count = var.domain_name != "" ? 1 : 0
  
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "toplist.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.ingress.dns_name
    zone_id                = aws_lb.ingress.zone_id
    evaluate_target_health = true
  }
}
