# EC2 Module - Variables

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for master node"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "master_security_group_id" {
  description = "Security group ID for master node"
  type        = string
}

variable "worker_security_group_id" {
  description = "Security group ID for worker nodes"
  type        = string
}
