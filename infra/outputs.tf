output "public_alb_dns" {
  value = aws_lb.public.dns_name
}

output "internal_alb_dns" {
  value = aws_lb.internal.dns_name
}

output "route53_record" {
  value = var.dns_name
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.app_cert.arn
}

output "aurora_writer_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  value = aws_rds_cluster.aurora.reader_endpoint
}
