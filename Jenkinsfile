pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
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

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'Jenkins-Pull-Push') {
                        sh "docker build -t manavpamnani06/boardgame-app:latest ."
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
                    def readPomVersion = readMavenPom file: 'pom.xml'
                    def versionTag = "${readPomVersion.version}-${BUILD_NUMBER}"

                    nexusArtifactUploader artifacts: [
                        [
                            artifactId: 'database_service_project',
                            classifier: '',
                            file: 'target/jacoco.exec',
                            type: 'jar'
                        ]
                    ],
                    credentialsId: 'nexus-auth',
                    groupId: 'com.javaproject',
                    nexusUrl: '13.235.23.68:8081',
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    repository: 'BoardGame-Release',
                    version: versionTag
                }
            }    
        }

        stage("Trivy Image Scan") {
            steps {
                sh 'trivy image manavpamnani06/boardgame-app:latest > target/trivyimg.txt'
            }
        }
        
        stage('Set Kubernetes Context') {
            steps {
                script {
                    // Ensure kubectl uses the correct context
                    sh 'kubectl config use-context arn:aws:eks:ap-south-1:061039777231:cluster/boardgame-cluster'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    dir('Kubernetes') {
                       kubeconfig(credentialsId: 'kubernetes', serverUrl: ''){
                        sh 'kubectl delete --all pods'
                        sh 'kubectl apply -f deployment-service.yml'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            emailext(
                attachLog: true,
                subject: "'${currentBuild.result}'",
                body: """Project: ${env.JOB_NAME}<br/>
                         Build Number: ${env.BUILD_NUMBER}<br/>
                         URL: ${env.BUILD_URL}<br/>""",
                to: 'manavpamnani03@gmail.com',
                attachmentsPattern: 'target/trivyfs.txt,target/trivyimg.txt'
            )
        }
    }
}
