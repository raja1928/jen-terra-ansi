@Library('sharedlibrary')_

pipeline {
    parameters {
        string 'GIT_URL'
        string 'BRANCH_NAME'
        string 'repository'
        string 'cluster'
    }
    environment {
        gitRepoURL = "${params.GIT_URL}"
        gitBranchName = "${params.BRANCH_NAME}"
        repoName = "${params.repository}"
        dockerImage = "061039788053.dkr.ecr.us-east-2.amazonaws.com/${repoName}"
        gitCommit = "${GIT_COMMIT[0..6]}"
        dockerTag = "${params.BRANCH_NAME}-${gitCommit}"
        AWS_REGION = 'us-east-2'
        EKS_CLUSTER_NAME = "${params.cluster}"
    }
     

    agent {label 'jen-slave-med'}
    stages {
        stage('Git Checkout') {
            steps {
                gitCheckout("$gitRepoURL", "refs/heads/$gitBranchName", 'githubCred')
            }
        }

        stage('Docker Build') {
            steps {
                    dockerImageBuild('$dockerImage', '$dockerTag')
            }
        }

        stage('Docker Push') {
            steps {
                dockerECRImagePush('$dockerImage', '$dockerTag', '$repoName', 'awsCred', 'us-east-2')
            }
        }
        stage('Initialize Terraform') {
            steps {
                script {
                    // Initialize Terraform
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    // Apply the Terraform configuration to create the resources
                    sh 'terraform apply -auto-approve -var "region=${AWS_REGION}" -var "cluster_name=${EKS_CLUSTER_NAME}"'
                }
            }
        }

        stage('Configure Kubeconfig') {
            steps {
                script {
                    // Configure kubectl with the created EKS cluster
                    sh '''
                    aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
                    kubectl get svc
                    '''
                }
            }
        }
        stage('APP Deploy by Ansible') {
            steps {
               sh """
                    ansible-playbook deployment.yaml --extra-vars "container_image_tag=${dockerTag}"
                    """ 
            }
        }
     
    }
}
