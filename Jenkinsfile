@Library('sharedlibrary')_

pipeline {
    parameters {
        string 'GIT_URL'
        string 'BRANCH_NAME'
        string 'repository'
        string 'eks-cluster'
    }
    environment {
        gitRepoURL = "${params.GIT_URL}"
        gitBranchName = "${params.BRANCH_NAME}"
        repoName = "${params.repository}"
        dockerImage = "061039788053.dkr.ecr.us-east-2.amazonaws.com/${repoName}"
        gitCommit = "${GIT_COMMIT[0..6]}"
        dockerTag = "${params.BRANCH_NAME}-${gitCommit}"
        AWS_REGION = 'us-east-2'
        EKS_CLUSTER_NAME = "${eks-cluster}"
    }
     

    agent {label 'docker-slave-server'}
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
        stage('APP Deploy by Ansible') {
            steps {
               sh """
                    ansible-playbook deployment.yaml --extra-vars "container_image_tag=${dockerTag}"
                    """ 
            }
        }
     
    }
}
