pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${env.PATH}"
        KUBE_CONTEXT = 'colima'
        KUBE_NAMESPACE = 'adminserver'
        HELM_RELEASE = 'adminserver'
        IMAGE_REPOSITORY = 'adminserver'
        DOCKER_HOST = 'unix:///Users/johanstigers/.colima/default/docker.sock'
    }

    stages {
        stage('Test') {
            steps {
                sh 'mvn -B clean test'
            }
        }

        stage('Build image') {
            steps {
                script {
                    env.IMAGE_TAG = "jenkins-${env.BUILD_NUMBER}"
                }
                writeFile file: '.docker/config.json', text: '{"auths": {}}\n'
                sh '''
                    docker --config "$WORKSPACE/.docker" \
                        build --tag "$IMAGE_REPOSITORY:$IMAGE_TAG" .
                '''
            }
        }

        stage('Validate Helm chart') {
            steps {
                sh 'helm lint ./helm/adminserver'
                sh 'helm template "$HELM_RELEASE" ./helm/adminserver --set-string image.tag="$IMAGE_TAG" > /dev/null'
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    helm --kube-context "$KUBE_CONTEXT" upgrade --install "$HELM_RELEASE" ./helm/adminserver \
                        --namespace "$KUBE_NAMESPACE" \
                        --create-namespace \
                        --set-string image.repository="$IMAGE_REPOSITORY" \
                        --set-string image.tag="$IMAGE_TAG" \
                        --wait \
                        --timeout 3m

                    kubectl --context "$KUBE_CONTEXT" --namespace "$KUBE_NAMESPACE" \
                        rollout status deployment/adminserver --timeout=120s
                '''
            }
        }

        stage('Smoke test') {
            steps {
                sh '''
                    kubectl --context "$KUBE_CONTEXT" --namespace "$KUBE_NAMESPACE" \
                        port-forward service/adminserver 18085:8085 > port-forward.log 2>&1 &
                    PORT_FORWARD_PID=$!
                    trap 'kill "$PORT_FORWARD_PID" 2>/dev/null || true' EXIT

                    for attempt in 1 2 3 4 5 6 7 8 9 10; do
                        if curl --fail --silent --show-error http://127.0.0.1:18085/actuator/health | grep -q '"status":"UP"'; then
                            exit 0
                        fi
                        sleep 1
                    done

                    cat port-forward.log
                    exit 1
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'port-forward.log', allowEmptyArchive: true
            deleteDir()
        }
    }
}
