pipeline {
    agent any

    environment {
        AWS_REGION = 'us-west-2' 
        EKS_CLUSTER_NAME = 'my-eks-cluster' 
        KUBECONFIG = credentials('kubeconfig') // Jenkins secret containing kubeconfig
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Checkout the code from the specified repository
                checkout scm //github repo
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    // Build and push Docker images for frontend and backend
                    sh '''
                    docker build -t workshop-frontend:v1 ./frontend
                    docker tag workshop-frontend:v1 public.ecr.aws/w8u5e4v2/workshop-frontend:v1
                    docker push public.ecr.aws/w8u5e4v2/workshop-frontend:v1

                    docker build -t workshop-backend:v1 ./backend
                    docker tag workshop-backend:v1 public.ecr.aws/w8u5e4v2/workshop-backend:v1
                    docker push public.ecr.aws/w8u5e4v2/workshop-backend:v1
                    '''
                }
            }
        }

        stage('Vulnerability Scanning') {
            steps {
                script {
                    // Scan Docker images for vulnerabilities using Trivy
                    sh '''
                    trivy image --exit-code 1 --no-progress public.ecr.aws/w8u5e4v2/workshop-frontend:v1
                    trivy image --exit-code 1 --no-progress public.ecr.aws/w8u5e4v2/workshop-backend:v1
                    '''
                }
            }
        }

        stage('Dependency Checks') {
            steps {
                script {
                    // Check dependencies for vulnerabilities using Snyk
                    sh '''
                    snyk test --all-projects
                    '''
                }
            }
        }

        stage('Configuration Validation') {
            steps {
                script {
                    // Validate Kubernetes manifests using kubeval 
                    sh '''
                    kubeval k8s_manifests/mongo_v1/secrets.yaml
                    kubeval k8s_manifests/mongo_v1/deploy.yaml
                    kubeval k8s_manifests/mongo_v1/service.yaml
                    kubeval k8s_manifests/backend-deployment.yaml
                    kubeval k8s_manifests/backend-service.yaml
                    kubeval k8s_manifests/frontend-deployment.yaml
                    kubeval k8s_manifests/frontend-service.yaml
                    kubeval k8s_manifests/full_stack_lb.yaml
                    '''
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                script {
                    // Update Kubernetes config to access the cluster
                    sh '''
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    '''
                }
            }
        }

        stage('Deploy MongoDB') {
            steps {
                script {
                    // Apply MongoDB Kubernetes manifests
                    sh '''
                    kubectl apply -f k8s_manifests/mongo_v1/secrets.yaml
                    kubectl apply -f k8s_manifests/mongo_v1/deploy.yaml
                    kubectl apply -f k8s_manifests/mongo_v1/service.yaml
                    '''
                }
            }
        }

        stage('Deploy Backend API') {
            steps {
                script {
                    // Apply Backend API Kubernetes manifests
                    sh '''
                    kubectl apply -f k8s_manifests/backend-deployment.yaml
                    kubectl apply -f k8s_manifests/backend-service.yaml
                    '''
                }
            }
        }

        stage('Deploy Frontend') {
            steps {
                script {
                    // Apply Frontend Kubernetes manifests
                    sh '''
                    kubectl apply -f k8s_manifests/frontend-deployment.yaml
                    kubectl apply -f k8s_manifests/frontend-service.yaml
                    '''
                }
            }
        }

        stage('Create Load Balancer') {
            steps {
                script {
                    // Apply the Load Balancer manifest
                    sh '''
                    kubectl apply -f k8s_manifests/full_stack_lb.yaml
                    '''
                }
            }
        }

        stage('Verify Autoscaler and Logs') {
            steps {
                script {
                    // Check autoscaler and logs
                    sh '''
                    kubectl get pods -n kube-system
                    kubectl logs -f -n kube-system -l app=cluster-autoscaler
                    kubectl logs -f -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
                    '''
                }
            }
        }

        stage('Grafana Setup') {
            steps {
                script {
                    // Modify Grafana service to LoadBalancer type
                    sh '''
                    kubectl get svc -n prometheus
                    kubectl edit svc prometheus-grafana -n prometheus --type merge --patch '{"spec": {"type": "LoadBalancer"}}'
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo 'Application deployment failed!'
        }
        success {
            echo 'Application has been successfully deployed!'
        }
    }
}
