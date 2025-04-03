output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.lb.dns_name
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web.private_ip
}
