output "s3_bucket_name" {
  value = aws_s3_bucket.report_bucket.bucket
}

output "s3_url" {
  value = "https://${aws_s3_bucket.report_bucket.bucket}.s3.amazonaws.com/report.html"
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.report_distribution.domain_name}/report.html"
}

