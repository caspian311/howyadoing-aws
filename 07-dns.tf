resource "aws_route53_record" "api-record" {
  zone_id = "Z12372QLT9T7P5"
  name    = "howyadoing-api.coffeemonkey.net"
  type    = "A"
  
  alias {
    name                   = aws_lb.api-lb.dns_name
    zone_id                = aws_lb.api-lb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "web-record" {
  zone_id = "Z12372QLT9T7P5"
  name    = "howyadoing.coffeemonkey.net"
  type    = "A"
  
  alias {
    name                   = "s3-website.us-east-2.amazonaws.com"
    zone_id                = aws_s3_bucket.website.hosted_zone_id
    evaluate_target_health = false
  }
}