# -------------------------------
# Terraform Output Values
# -------------------------------

# Output the actual S3 bucket name
output "s3_bucket_name" {
  description = "The name of the S3 bucket created for reports"
  value       = aws_s3_bucket.report_bucket.bucket
}

# Direct S3 URL for testing or manual access
output "s3_url" {
  description = "Public S3 URL for the uploaded report (HTML)"
  value       = "https://${aws_s3_bucket.report_bucket.bucket}.s3.${var.aws_region}.amazonaws.com/sales_report.html"
}

# CloudFront URL (preferred for final hosted report)
output "cloudfront_url" {
  description = "CloudFront distribution URL for the hosted report"
  value       = "https://${aws_cloudfront_distribution.report_distribution.domain_name}/sales_report.html"
}
