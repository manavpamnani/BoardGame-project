pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3' // Ensure this matches Jenkins tool config
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        BUILD_VERSION = "2.5.6-${BUILD_NUMBER}"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/manavpamnani/BoardGame-project.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=BoardGame \
                        -Dsonar.projectName=BoardGame \
                        -Dsonar.java.binaries=target
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: true, credentialsId: 'SonarQube-Token'
                }
            }
        }

        stage('Trivy File System Scan') {
            steps {
                sh 'mkdir -p target && trivy fs . > target/trivyfs.txt'
            }
        }
        stage("TRIVY Image Scan"){
            steps{
                sh "trivy image manavpamnani06/sonarqube:latest > trivyimage.txt" 
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'Jenkins-Pull-Push') {
                        sh "docker build -t boardgame-app ."
                        sh "docker tag boardgame-app manavpamnani06/boardgame-app:latest"
                        sh "docker push manavpamnani06/boardgame-app:latest"
                    }
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            when {
                expression {
                    fileExists('target/jacoco.exec')
                }
            }
            steps {
                script {
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: '13.234.115.100:8081',
                        groupId: 'com.boardgame',
                        version: "${BUILD_VERSION}",
                        repository: 'BoardGame-release',
                        credentialsId: 'nexus-auth',
                        artifacts: [[
                            artifactId: 'boardgame-app',
                            classifier: '',
                            file: 'target/jacoco.exec',
                            type: 'jar'
                        ]]
                    )
                }
            }
        }
    }
        
    post {
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: "Project: ${env.JOB_NAME}<br/>" +
                    "Build Number: ${env.BUILD_NUMBER}<br/>" +
                    "URL: ${env.BUILD_URL}<br/>",
                to: 'manavpamnani03@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'

            echo "Pipeline completed. Cleaning workspace..."
            cleanWs()
        }
    }
}
