# Security Groups Module - Outputs

output "master_security_group_id" {
  description = "ID of the master security group"
  value       = aws_security_group.master.id
}

output "worker_security_group_id" {
  description = "ID of the worker security group"
  value       = aws_security_group.worker.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}
