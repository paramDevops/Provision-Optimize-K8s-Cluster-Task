# output the ec2 instane ids
output "ec2_instances" {
  description = "List of instances"
  value       = aws_instance.nginx_app[*].id
}
