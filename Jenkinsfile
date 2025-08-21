pipeline {
    agent any

    environment {
        IMAGE = "ros2_ci:latest"
        COMPOSE_FILE = "/home/user/ros2_ws/src/ros2_ci/docker-compose.yml"
        PROJECT_DIR = "/home/user/ros2_ws/src/ros2_ci"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                sh '''
                    set -euo pipefail
                    cd ${PROJECT_DIR}
                    echo "[INFO] Building Docker image: ${IMAGE}"
                    sudo docker build -t ${IMAGE} .
                '''
            }
        }

        stage('Run ROS + Tests (Compose)') {
            steps {
                sh '''
                    set -euo pipefail
                    cd ${PROJECT_DIR}
                    echo "[INFO] Starting docker-compose"
                    sudo docker compose -f ${COMPOSE_FILE} up --build --abort-on-container-exit --exit-code-from ros_tests
                    echo "[INFO] Shutting down docker-compose"
                    sudo docker compose -f ${COMPOSE_FILE} down -v --remove-orphans
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Docker Compose + ROS tests completed successfully!"
        }
        failure {
            echo "❌ Docker Compose or ROS tests failed. Check console output."
        }
    }
}
