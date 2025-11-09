pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        S3_BUCKET = 'my-report-bucket'           // replace with your actual S3 bucket
        REPORT_DIR = 'reports'
        GIT_REPO = 'https://github.com/yashvireddyy/report-generator-devops-pipeline.git'
        BRANCH = 'main'                         // change if using another branch
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo '📥 Cloning project repository from GitHub...'
                git branch: "${BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image for report generation...'
                bat 'docker build -t report-generator .'
            }
        }

        stage('Run Report Generator') {
            steps {
                echo '🧠 Running Python report generator inside container...'
                bat '''
                    docker run --rm ^
                        -v "%cd%\\reports:/app/reports" ^
                        report-generator python report_generator.py

                    echo "📦 Compressing generated reports..."
                    
                '''
            }
        }

        stage('Terraform Infrastructure Setup') {
            steps {
                echo '🌍 Setting up AWS infrastructure using Terraform...'
                dir('terraform') {
                    bat '''
                        terraform init -input=false
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Upload Reports to S3') {
            steps {
                echo '☁️ Uploading generated reports to AWS S3...'
                withAWS(region: "${AWS_DEFAULT_REGION}", credentials: 'aws-jenkins-creds') {
                    bat '''
                        aws s3 sync ./reports s3://$S3_BUCKET --delete
                    '''
                }
            }
        }

        stage('Verification / Output') {
            steps {
                echo '🔍 Verifying upload and displaying URLs...'
                script {
                    def cloudfront_url = bat(
                        script: "terraform -chdir=terraform output -raw cloudfront_url",
                        returnStdout: true
                    ).trim()
                    echo "✅ Reports uploaded successfully!"
                    echo "S3 URL: https://${S3_BUCKET}.s3.${AWS_DEFAULT_REGION}.amazonaws.com/sales_report.html"
                    echo "CloudFront URL: ${cloudfront_url}"
                }
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            cleanWs()
        }
        failure {
            echo '❌ Pipeline failed. Please check Jenkins logs for details.'
        }
    }
}

