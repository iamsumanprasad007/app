# Outputs for Dev Environment

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "master_public_ip" {
  description = "Public IP of the master node"
  value       = module.ec2.master_public_ip
}

output "master_private_ip" {
  description = "Private IP of the master node"
  value       = module.ec2.master_private_ip
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = module.ec2.worker_public_ips
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = module.ec2.worker_private_ips
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.ingress.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.ingress.zone_id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for cluster setup"
  value       = module.ec2.s3_bucket_name
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from master node"
  value       = module.ec2.kubeconfig_command
}

output "ssh_master_command" {
  description = "SSH command to connect to master node"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.ec2.master_public_ip}"
}

output "ssh_worker_commands" {
  description = "SSH commands to connect to worker nodes"
  value       = [for i, ip in module.ec2.worker_public_ips : "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${ip}"]
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = "https://${module.ec2.master_public_ip}:6443"
}

output "application_url" {
  description = "Application URL via load balancer"
  value       = "http://${aws_lb.ingress.dns_name}"
}

output "route53_nameservers" {
  description = "Route53 nameservers (if domain configured)"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : []
}
