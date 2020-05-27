resource "aws_acm_certificate" "api-cert" {
  domain_name       = "howyadoing-api.coffeemonkey.net"
  validation_method = "EMAIL"
}

resource "aws_acm_certificate" "web-cert" {
  domain_name       = "howyadoing.coffeemonkey.net"
  validation_method = "EMAIL"
}