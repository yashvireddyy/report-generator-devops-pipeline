pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        S3_BUCKET = 'my-devops-pipeline-bucket'
        REPORT_DIR = 'reports'
        GIT_REPO = 'https://github.com/yashvireddyy/report-generator-devops-pipeline.git'
        BRANCH = 'main'
        AWS_CREDENTIALS = 'aws-credentials-s3' // Jenkins IAM user credentials
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo '📥 Cloning the project repository from GitHub...'
                deleteDir()
                git branch: "${BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image for report generator...'
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
                echo '✅ Reports generated in /reports folder.'
            }
        }

        stage('Terraform Setup') {
            steps {
                echo '🌍 Applying Terraform (S3 + CloudFront)...'
                withAWS(region: "${AWS_DEFAULT_REGION}", credentials: "${AWS_CREDENTIALS}") {
                    dir('terraform') {
                        bat '''
                            terraform init -input=false
                            terraform plan -out=tfplan -var "bucket_name=${S3_BUCKET}" -var "build_number=%BUILD_NUMBER%" -var "aws_region=${AWS_DEFAULT_REGION}"
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Upload Reports to S3') {
            steps {
                echo '☁️ Uploading reports to S3...'
                withAWS(region: "${AWS_DEFAULT_REGION}", credentials: "${AWS_CREDENTIALS}") {
                    bat '''
                        timeout 5
                        aws s3 sync %REPORT_DIR% s3://%S3_BUCKET% --delete
                    '''
                }
            }
        }

        stage('Invalidate CloudFront Cache') {
            steps {
                echo '♻️ Invalidating CloudFront cache...'
                script {
                    def cf_id = powershell(
                        script: "terraform -chdir=terraform output -raw cloudfront_distribution_id",
                        returnStdout: true
                    ).trim()

                    withAWS(region: "${AWS_DEFAULT_REGION}", credentials: "${AWS_CREDENTIALS}") {
                        bat "aws cloudfront create-invalidation --distribution-id ${cf_id} --paths \"/*\""
                    }
                }
            }
        }

        stage('Verification / Output URLs') {
            steps {
                echo '🔍 Fetching S3 & CloudFront URLs...'
                script {
                    def cloudfront_url = powershell(
                        script: "terraform -chdir=terraform output -raw cloudfront_url",
                        returnStdout: true
                    ).trim()

                    def s3_url = powershell(
                        script: "terraform -chdir=terraform output -raw s3_url",
                        returnStdout: true
                    ).trim()

                    echo "🌐 CloudFront URL: ${cloudfront_url}/sales_report.html"
                    echo "☁️ S3 URL: ${s3_url}"
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
            echo '❌ Pipeline failed. Check Jenkins logs.'
        }
    }
}
