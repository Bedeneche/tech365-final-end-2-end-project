pipeline{
    agent any
    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        AWS_ACCOUNT_ID = credentials('AWS_ACCOUNT_ID')
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/node-repo"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
  
     stages{
        stage ('Checkout Code'){
            steps {
                checkout scm
            }
        }
         stage ('Login to ECR'){
            steps {
                withCredentials([aws(credentialsId: 'AWS-ECR-CRED', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_DEFAULT_REGION \
                        | docker login --username AWS --password-stdin $REPOSITORY_URI
                    '''
                }
            }
        }
     }
}