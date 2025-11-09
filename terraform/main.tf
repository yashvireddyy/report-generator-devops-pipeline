provider "aws" {
  region = var.aws_region
}

# -------------------------------
# S3 Bucket for Reports
# -------------------------------
resource "aws_s3_bucket" "report_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "report-generator-bucket"
    Environment = "Dev"
  }
}

# Public access block to allow CloudFront/public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.report_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket Policy (public read for reports)
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.report_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowPublicRead",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.report_bucket.arn}/*"
      }
    ]
  })
}

# -------------------------------
# CloudFront Distribution
# -------------------------------
resource "aws_cloudfront_distribution" "report_distribution" {
  origin {
    domain_name = aws_s3_bucket.report_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.report_bucket.id}"
  }

  enabled             = true
  default_root_object = "report.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.report_bucket.id}"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "report-distribution"
  }
}

# -------------------------------
# IAM Policy for Jenkins User
# -------------------------------
# Replace the username below with your actual IAM username created for Jenkins
# Example: "jenkins-deploy-user" or "report-generator-user"
resource "aws_iam_user_policy" "jenkins_policy" {
  name = "jenkins-s3-upload-policy"
  user = "jenkins-deploy-user"   # <-- put your IAM username here in quotes!

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:DeleteObject",
          "cloudfront:CreateInvalidation"
        ],
        Resource = [
          aws_s3_bucket.report_bucket.arn,
          "${aws_s3_bucket.report_bucket.arn}/*"
        ]
      }
    ]
  })
}

# -------------------------------
# Terraform Outputs
# -------------------------------
output "s3_bucket_name" {
  value = aws_s3_bucket.report_bucket.bucket
}

output "s3_url" {
  value = "https://${aws_s3_bucket.report_bucket.bucket}.s3.amazonaws.com/report.html"
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.report_distribution.domain_name}/report.html"
}
