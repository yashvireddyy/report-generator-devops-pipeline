pipeline {
    agent any

    environment {
        AWS_CREDENTIALS = 'aws-credentials-s3'  // Jenkins AWS credentials ID
        AWS_DEFAULT_REGION = 'ap-south-1'           // Change as needed
        S3_BUCKET = 'my-devops-pipeline-bucket'           // Change as needed
        CLOUDFRONT_ID = 'E1AW7KMP65SDP6'       // Change as needed
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo "📥 Checking out source code..."
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/main']], 
                    userRemoteConfigs: [[url: 'https://github.com/yashvireddyy/report-generator-devops-pipeline.git']]
                ])
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🛠 Building Docker image for report generator..."
                bat 'docker build -t report-generator .'
            }
        }

        stage('Run Report Generator') {
            steps {
                echo "⚡ Running Python report generator inside Docker container..."
                bat """
                docker run --rm ^
                    -v "%CD%\\reports:/app/reports" ^
                    report-generator python report_generator.py
                """
                echo "✅ Reports generated in /reports folder."
            }
        }

        stage('Terraform Setup') {
            steps {
                echo "🌐 Applying Terraform (S3 + CloudFront)..."
                withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEFAULT_REGION}") {
                    dir('terraform') {
                        bat 'terraform init -input=false'
                        bat """
                        terraform plan -out=tfplan ^
                            -var "bucket_name=${S3_BUCKET}" ^
                            -var "build_number=${BUILD_NUMBER}" ^
                            -var "aws_region=${AWS_DEFAULT_REGION}"
                        """
                        bat 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Upload Reports to S3') {
            steps {
                echo "☁️ Uploading reports to S3..."
                withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEFAULT_REGION}") {
                    bat """
                    aws s3 sync reports s3://${S3_BUCKET}/reports --delete
                    """
                }
            }
        }

        stage('Invalidate CloudFront Cache') {
            steps {
                echo "🧹 Invalidating CloudFront cache..."
                withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEFAULT_REGION}") {
                    bat """
                    aws cloudfront create-invalidation ^
                        --distribution-id ${CLOUDFRONT_ID} ^
                        --paths "/*"
                    """
                }
            }
        }

        stage('Verification / Output URLs') {
            steps {
                echo "🔗 Reports uploaded to S3. Access them via:"
                echo "https://${S3_BUCKET}.s3.${AWS_DEFAULT_REGION}.amazonaws.com/reports/"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check Jenkins logs for details."
        }
    }
}
