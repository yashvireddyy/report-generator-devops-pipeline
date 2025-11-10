pipeline {
    agent any

    environment {
        // Set your AWS credentials ID from Jenkins Credentials Manager
        AWS_CREDENTIALS = 'aws-credentials-s3'
        AWS_DEFAULT_REGION = 'ap-south-1'
        S3_BUCKET = 'my-devops-bucket'
        DOCKER_IMAGE = 'report-generator'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo "📥 Cloning the project repository from GitHub..."
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[url: 'https://github.com/yashvireddyy/report-generator-devops-pipeline.git']]
                ])
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🛠 Building Docker image for report generator..."
                bat "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Run Report Generator') {
            steps {
                echo "🚀 Running Python report generator inside Docker container..."
                bat """
                docker run --rm ^
                    -v "${WORKSPACE}\\reports:/app/reports" ^
                    ${DOCKER_IMAGE} python report_generator.py
                """
                echo "✅ Reports generated in /reports folder."
            }
        }

        stage('Terraform Setup') {
            steps {
                echo "🌐 Applying Terraform (S3 + CloudFront)..."
                withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEFAULT_REGION}") {
                    dir('terraform') {
                        // Initialize Terraform
                        bat 'terraform init -input=false'

                        // Plan with interpolated variables
                        bat """
                        terraform plan -out=tfplan ^
                            -var "bucket_name=${S3_BUCKET}" ^
                            -var "build_number=${BUILD_NUMBER}" ^
                            -var "aws_region=${AWS_DEFAULT_REGION}"
                        """

                        // Apply the plan
                        bat 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Upload Reports to S3') {
            steps {
                echo "📤 Uploading reports to S3..."
                withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEFAULT_REGION}") {
                    bat """
                    aws s3 sync ${WORKSPACE}\\reports s3://${S3_BUCKET}/reports --delete
                    """
                }
            }
        }

        stage('Invalidate CloudFront Cache') {
            steps {
                echo "🧹 Invalidating CloudFront cache..."
                withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEFAULT_REGION}") {
                    // Replace with your CloudFront Distribution ID
                    def cfDistId = 'YOUR_CLOUDFRONT_ID'
                    bat """
                    aws cloudfront create-invalidation ^
                        --distribution-id ${cfDistId} ^
                        --paths "/*"
                    """
                }
            }
        }

        stage('Verification / Output URLs') {
            steps {
                echo "🔗 Reports deployed successfully!"
                echo "S3 URL: https://s3.console.aws.amazon.com/s3/buckets/${S3_BUCKET}/reports"
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check Jenkins logs for details."
        }
    }
}
