pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        stage('Validate Commit Messages') {
            steps {
                script {
                    def latestCommitMessage = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()

                    if (!(latestCommitMessage =~ /^(fix|feat|chore|docs|style|refactor|test|perf|build|ci|revert|version|merge|hotfix|wip)\:.*/)) {
                        error "The commit message does not follow the Conventional Commit format:\n${latestCommitMessage}"
                    }
                }
            }
        }
        stage('Initialize Terraform') {
            steps {
                script {
                    try {
                        sh 'terraform init -input=false -backend=false'
                    } catch (Exception e) {
                        error "Failed to initialize Terraform: ${e.message}"
                    }
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                script {
                    def formatCheck = sh(script: 'terraform fmt -check -diff', returnStatus: true)
                    if (formatCheck != 0) {
                        error "Terraform files are not properly formatted. Please run 'terraform fmt' to fix formatting issues."
                    }
                }
            }
        }

        stage('Terraform Syntax Validation') {
            steps {
                script {
                    def validate = sh(script: 'terraform validate', returnStatus: true)
                    if (validate != 0) {
                        error "Terraform validation failed. Please check the syntax of your Terraform files."
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
