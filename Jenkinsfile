pipeline {
    agent any

    environment {
        AWS_CREDENTIALS = 'aws-credentials-s3'  // Jenkins AWS credentials ID
        AWS_DEFAULT_REGION = 'ap-south-1'       // AWS region
        S3_BUCKET = 'my-devops-pipeline-bucket' // Single static bucket
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
                echo "🛠 Building Docker image..."
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
                echo "✅ Reports generated successfully."
            }
        }

        stage('Terraform Setup') {
            steps {
                echo "🌍 Setting up infrastructure via Terraform..."
                withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_DEFAULT_REGION}") {
                    dir('terraform') {
                        bat 'terraform init -input=false'
                        bat """
                        terraform plan -out=tfplan ^
                            -var "bucket_name=${S3_BUCKET}" ^
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

        stage('Fetch CloudFront ID & Invalidate Cache') {
            steps {
                echo "🧹 Invalidating CloudFront cache..."
                script {
                    def cfDistId = powershell(
                        script: "terraform -chdir=terraform output -raw cloudfront_url | ForEach-Object { ($_ -split '/')[2] }",
                        returnStdout: true
                    ).trim()
                    bat "aws cloudfront create-invalidation --distribution-id ${cfDistId} --paths '/*'"
                }
            }
        }

        stage('Verification / Output URLs') {
            steps {
                echo "🔗 Reports uploaded successfully. Access them via:"
                echo "S3: https://${S3_BUCKET}.s3.${AWS_DEFAULT_REGION}.amazonaws.com/reports/sales_report.html"
                echo "Or view via CloudFront (faster): see terraform output below 👇"
                bat 'terraform -chdir=terraform output'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs for errors."
        }
    }
}
