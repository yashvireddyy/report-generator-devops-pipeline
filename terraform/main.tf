provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------
# Use an existing S3 bucket instead of creating a new one
# ---------------------------------------------------------
data "aws_s3_bucket" "existing_bucket" {
  bucket = var.bucket_name
}

# ---------------------------------------------------------
# CloudFront OAI (still managed by Terraform)
# ---------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for existing report-generator-bucket"
}

# ---------------------------------------------------------
# CloudFront Distribution (uses existing S3 bucket)
# ---------------------------------------------------------
resource "aws_cloudfront_distribution" "report_distribution" {
  origin {
    domain_name = data.aws_s3_bucket.existing_bucket.bucket_regional_domain_name
    origin_id   = "S3-${data.aws_s3_bucket.existing_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "sales_report.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${data.aws_s3_bucket.existing_bucket.id}"
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

# ---------------------------------------------------------
# S3 Bucket Policy for CloudFront Access
# ---------------------------------------------------------
resource "aws_s3_bucket_policy" "private_policy" {
  bucket = data.aws_s3_bucket.existing_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess",
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action   = ["s3:GetObject"],
        Resource = "${data.aws_s3_bucket.existing_bucket.arn}/*"
      }
    ]
  })
}

# ---------------------------------------------------------
# IAM Policy for Jenkins uploads
# ---------------------------------------------------------
resource "aws_iam_user_policy" "jenkins_policy" {
  name = "jenkins-s3-upload-policy"
  user = var.jenkins_user_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "${data.aws_s3_bucket.existing_bucket.arn}",
          "${data.aws_s3_bucket.existing_bucket.arn}/*"
        ]
      }
    ]
  })
}

# ---------------------------------------------------------
# Outputs
# ---------------------------------------------------------
output "s3_bucket_name" {
  value = data.aws_s3_bucket.existing_bucket.bucket
}

output "s3_url" {
  value = "https://${data.aws_s3_bucket.existing_bucket.bucket}.s3.${var.aws_region}.amazonaws.com/reports/sales_report.html"
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.report_distribution.domain_name}/reports/sales_report.html"
}
