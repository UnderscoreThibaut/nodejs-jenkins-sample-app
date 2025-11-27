pipeline {
    agent any

    environment {
        APP_NAME       = 'nodejs-app'
        IMAGE_NAME     = 'nodejs-app'          // Docker image name
        CONTAINER_BASE = 'nodejs-app'          // Base container name (branch is appended)
    }

    options {
        disableConcurrentBuilds()              // No concurrent build per branch
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install & Test') {
            steps {
                sh '''
                    # Install dependencies
                    if [ -f package-lock.json ]; then
                      npm ci
                    else
                      npm install
                    fi

                    # Run tests (adjust if you use another test script)
                    npm test
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                // "SonarQube" must match the server name configured in Jenkins
                withSonarQubeEnv('SonarQube') {
                    sh """
                        sonar-scanner \
                          -Dsonar.projectKey=${APP_NAME}-${BRANCH_NAME} \
                          -Dsonar.projectName=${APP_NAME}-${BRANCH_NAME} \
                          -Dsonar.sources=. \
                          -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                    """
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
                    echo "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}"
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag  ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:${LATEST_TAG}
                """
            }
        }

        stage('Stop and Remove Old Container') {
            steps {
                sh """
                    if docker ps -a --format '{{.Names}}' | grep -w ${CONTAINER_NAME} >/dev/null 2>&1; then
                      echo "Stopping and removing old container ${CONTAINER_NAME}..."
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
                    // Different host ports for branches so they can run in parallel
                    // Assumes your Node app listens on container port 3000
                    def hostPort = (BRANCH_NAME == 'main') ? '3000' : '3001'

                    sh """
                        echo "Starting new container ${CONTAINER_NAME} on host port ${hostPort}..."
                        docker run -d --name ${CONTAINER_NAME} \
                          -p ${hostPort}:3000 \
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
        success {
            echo "Build & deploy successful for branch ${BRANCH_NAME}"
        }
        failure {
            echo "Build FAILED for branch ${BRANCH_NAME}"
        }
    }
}
