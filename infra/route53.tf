resource "aws_route53_record" "app_alias" {
  zone_id = var.route53_zone_id
  name    = var.dns_name
  type    = "A"

  alias {
    name                   = aws_lb.public.dns_name
    zone_id                = aws_lb.public.zone_id
    evaluate_target_health = true
  }
}
