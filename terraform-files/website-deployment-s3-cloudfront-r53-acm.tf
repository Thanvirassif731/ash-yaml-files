# ---Configure the AWS provider---
provider "aws" {
  region = "ap-south-1" 
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


# ---DNS and SSL (Route 53 & ACM)---
data "aws_route53_zone" "main" {
  name = "yourdomain.com"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = "www.yourdomain.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# This tells Terraform: "Wait until the certificate is actually issued before moving on"
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


# ---S3 Bucket for Static Website Hosting---
resource "aws_s3_bucket" "website_bucket" {
  bucket = "www.yourdomain.com"
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ---CloudFront with OAC (Origin Access Control)---
# Create the OAC
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac-test-site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "distro" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"
  aliases             = ["www.yourdomain.com"]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
}


# ---(Final) IAM Role and Policy for CloudFront OAC---
# Allow CloudFront to access S3
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.distro.arn
          }
        }
      }
    ]
  })
}

# Route 53 Alias Record
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.yourdomain.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distro.domain_name
    zone_id                = aws_cloudfront_distribution.distro.hosted_zone_id
    evaluate_target_health = false
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.website_bucket.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.distro.id
}

output "website_url" {
  value = "https://www.yourdomain.com"
}
