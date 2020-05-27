resource "aws_route53_zone" "site_zone" {
  name    = "coffeemonkey.net"
  comment = "HostedZone created by Route53 Registrar"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "api-record" {
  zone_id = aws_route53_zone.site_zone.zone_id
  name    = var.api_name
  type    = "A"
  
  alias {
    name                   = aws_lb.api-lb.dns_name
    zone_id                = aws_lb.api-lb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "web-record" {
  zone_id = aws_route53_zone.site_zone.zone_id
  name    = var.site_bucket_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}