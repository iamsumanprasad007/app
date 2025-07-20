# EC2 Module - Outputs

output "master_instance_id" {
  description = "ID of the master instance"
  value       = aws_instance.master.id
}

output "master_public_ip" {
  description = "Public IP of the master instance"
  value       = aws_instance.master.public_ip
}

output "master_private_ip" {
  description = "Private IP of the master instance"
  value       = aws_instance.master.private_ip
}

output "worker_instance_ids" {
  description = "IDs of the worker instances"
  value       = aws_instance.worker[*].id
}

output "worker_public_ips" {
  description = "Public IPs of the worker instances"
  value       = aws_instance.worker[*].public_ip
}

output "worker_private_ips" {
  description = "Private IPs of the worker instances"
  value       = aws_instance.worker[*].private_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used for cluster setup"
  value       = aws_s3_bucket.k8s_setup.bucket
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from master node"
  value       = "scp -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.master.public_ip}:/home/ubuntu/.kube/config ~/.kube/config"
}
