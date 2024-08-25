
# Output the acm cert arn
output "alb_dns_name" {
  value       = aws_route53_record.dns_record.fqdn
  description = "The DNS name of the ALB"
}