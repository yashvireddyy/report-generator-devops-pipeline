# -------------------------------
# AWS Configuration
# -------------------------------
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

# -------------------------------
# S3 Configuration
# -------------------------------
variable "bucket_name" {
  description = "Unique name of the S3 bucket for report uploads"
  type        = string
  default     = "my-devops-pipeline-bucket"   # ✅ use your actual bucket name
}

# -------------------------------
# CloudFront Configuration
# -------------------------------
variable "cloudfront_comment" {
  description = "Comment for identifying the CloudFront distribution"
  type        = string
  default     = "Automated Report Generator Distribution"
}

# -------------------------------
# Jenkins IAM User
# -------------------------------
variable "jenkins_user_name" {
  description = "IAM username used by Jenkins to access S3 and CloudFront"
  type        = string
  default     = "jenkins-deploy-user"   # ✅ replace with your actual IAM user name
}
