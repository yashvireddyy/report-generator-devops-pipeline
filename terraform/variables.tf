variable "aws_region" {
  description = "AWS region for all resources"
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for reports"
  default     = "my-devops-pipeline-bucket"
}

variable "cloudfront_comment" {
  description = "CloudFront distribution comment"
  default     = "Automated Report Generator Distribution"
}

variable "jenkins_user_name" {
  description = "Existing IAM user name for Jenkins"
  type        = string
  default     = "jenkins-deploy-user"  # <-- change to your IAM user name
}
