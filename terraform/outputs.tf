# outputs.tf — For existing bucket setup
output "s3_bucket_name" {
  description = "The name of the existing S3 bucket used for reports"
  value       = data.aws_s3_bucket.existing_bucket.bucket
}

output "s3_url" {
  description = "Public S3 URL of the HTML report"
  value       = "https://${data.aws_s3_bucket.existing_bucket.bucket}.s3.${var.aws_region}.amazonaws.com/reports/sales_report.html"
}

output "cloudfront_url" {
  description = "CloudFront distribution URL to access reports"
  value       = "https://${aws_cloudfront_distribution.report_distribution.domain_name}/reports/sales_report.html"
}
