pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        S3_BUCKET = 'my-devops-pipeline-bucket'
        REPORT_DIR = 'reports'
        GIT_REPO = 'https://github.com/yashvireddyy/report-generator-devops-pipeline.git'
        BRANCH = 'main'
        AWS_CREDENTIALS = 'aws-credentials-s3' // Jenkins credential ID linked to IAM user 'jenkins-deploy-user'
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo '📥 Cloning the project repository from GitHub...'
                deleteDir() // Ensures clean workspace before fetching
                git branch: "${BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image for automated report generation...'
                bat 'docker build -t report-generator .'
            }
        }

        stage('Run Report Generator') {
            steps {
                echo '🧠 Running Python report generator inside Docker container...'
                bat '''
                    docker run --rm ^
                        -v "%cd%\\reports:/app/reports" ^
                        report-generator python report_generator.py
                '''
                echo '✅ Reports generated successfully and stored in /reports folder.'
            }
        }

        stage('Terraform Infrastructure Setup') {
            steps {
                echo '🌍 Setting up AWS infrastructure using Terraform (S3 + CloudFront)...'
                withAWS(region: "${AWS_DEFAULT_REGION}", credentials: "${AWS_CREDENTIALS}") {
                    dir('terraform') {
                        bat '''
                            terraform init -input=false
                            terraform plan -out=tfplan
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Upload Reports to S3') {
            steps {
                echo '☁️ Uploading generated reports to AWS S3 bucket...'
                withAWS(region: "${AWS_DEFAULT_REGION}", credentials: "${AWS_CREDENTIALS}") {
                    // Wait briefly to ensure AWS CLI readiness
                    bat '''
                        timeout 5
                        aws s3 sync %REPORT_DIR% s3://%S3_BUCKET% --delete
                    '''
                }
            }
        }

        stage('Verification / Output URLs') {
            steps {
                echo '🔍 Verifying deployment and fetching CloudFront URL...'
                script {
                    def cloudfront_url = powershell(
                        script: "terraform -chdir=terraform output -raw cloudfront_url",
                        returnStdout: true
                    ).trim()

                    echo "✅ Reports successfully uploaded!"
                    echo "🌐 S3 URL: https://${S3_BUCKET}.s3.${AWS_DEFAULT_REGION}.amazonaws.com/sales_report.html"
                    echo "🚀 CloudFront URL: ${cloudfront_url}"
                }
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline completed successfully! Cleaning up workspace...'
            cleanWs()
        }
        failure {
            echo '❌ Pipeline failed. Please review the Jenkins console logs for details.'
        }
    }
}
