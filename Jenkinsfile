pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'nodejs-app'                  // TODO: your image name
        CONTAINER_BASE = 'nodejs-app'                  // base name; we append branch
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('My SonarQube') {
                    // Example for Maven; replace with your build tool
                    sh '''
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=${BRANCH_NAME}
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG      = "${BRANCH_NAME}-${env.BUILD_NUMBER}"
                    env.LATEST_TAG     = "${BRANCH_NAME}-latest"
                    env.CONTAINER_NAME = "${CONTAINER_BASE}-${BRANCH_NAME}"
                }

                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag  ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:${LATEST_TAG}
                """
            }
        }

        stage('Stop and Remove Old Container') {
            steps {
                sh """
                    if docker ps -a --format '{{.Names}}' | grep -w ${CONTAINER_NAME} >/dev/null 2>&1; then
                      echo "Stopping old container ${CONTAINER_NAME}..."
                      docker rm -f ${CONTAINER_NAME} || true
                    else
                      echo "No existing container named ${CONTAINER_NAME}"
                    fi
                """
            }
        }

        stage('Run New Container') {
            steps {
                script {
                    // Different ports per branch
                    def portMapping = (BRANCH_NAME == 'main')
                        ? '8080:80'      // TODO adjust if needed
                        : '8081:80'      // develop branch port
                        
                    sh """
                        docker run -d --name ${CONTAINER_NAME} \
                          -p ${portMapping} \
                          ${IMAGE_NAME}:${LATEST_TAG}
                    """
                }
            }
        }

        stage('Delete Old Images For This Branch') {
            steps {
                sh """
                    echo "Cleaning old images for branch ${BRANCH_NAME}..."
                    docker images ${IMAGE_NAME} --format '{{.Repository}}:{{.Tag}} {{.ID}}' \
                      | grep "${IMAGE_NAME}:${BRANCH_NAME}-" \
                      | sort \
                      | head -n -1 \
                      | awk '{print \$2}' \
                      | xargs -r docker rmi || true
                """
            }
        }
    }

    post {
        failure {
            echo "Build failed on branch ${BRANCH_NAME}"
        }
    }
}
