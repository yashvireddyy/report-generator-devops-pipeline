provider "aws" {
  region = var.aws_region
}



# S3 Bucket (Private)
resource "aws_s3_bucket" "report_bucket" {
  bucket = "${var.bucket_name}-${var.build_number}"
  tags = {
    Name        = "report-generator-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.report_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAI
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for report-generator-bucket"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "report_distribution" {
  origin {
    domain_name = aws_s3_bucket.report_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.report_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "sales_report.html"

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

# S3 Bucket Policy for CloudFront
resource "aws_s3_bucket_policy" "private_policy" {
  bucket = aws_s3_bucket.report_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.report_bucket.arn}/*"
      }
    ]
  })
}

# IAM Policy for Jenkins to upload files
resource "aws_iam_user_policy" "jenkins_policy" {
  name = "jenkins-s3-upload-policy"
  user = "jenkins-deploy-user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.report_bucket.arn}",
          "${aws_s3_bucket.report_bucket.arn}/*"
        ]
      }
    ]
  })
}


