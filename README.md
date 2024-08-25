# Provision and Optimize EKS Cluster

## Overview

This project involves provisioning and optimizing a Kubernetes cluster on AWS using Terraform and deploying a microservices-based application. The setup includes automated CI/CD pipelines, security best practices, logging, and monitoring.

---

## Kubernetes Cluster Provisioning

### Terraform Configuration

Provisioning: Provides Terraform configuration to provision a Kubernetes cluster in an AWS cloud environment.
Modules: Uses reusable Terraform modules, including in-built AWS modules (`source = "terraform-aws-modules"`), for modular and scalable infrastructure.
Environments: Configured with separate environment structures for development, staging, and production (`..\kustomize\nginx\overlays`).

---

## Automation

### CI/CD Pipelines

Infrastructure Pipeline: `jenkinsfile.infra` – Automates provisioning and configuration of the Kubernetes cluster.
Application Pipeline: `jenkinsfile.app` – Automates the deployment of the microservices application.

### Load Balancing and Autoscaling

Load Balancer: Configured to manage external traffic to the application.
Autoscaler: Kubernetes autoscaler and load balancer controller are set up, and logs are monitored.

Note:
Environment Variables: Update `AWS_REGION`, `EKS_CLUSTER_NAME`, and other environment-specific values as needed.
Kubeconfig: Store `kubeconfig` as a Jenkins secret and configure Jenkins credentials accordingly.
Docker and Helm: Ensure Docker and Helm are installed and configured on Jenkins agents.

---

## Logging and Monitoring

### Setup

Grafana: Configured to use a LoadBalancer service type for external access.
Prometheus & Grafana: Used for logging and monitoring to track resource utilization, system health, and application performance.

### Configuration

Grafana Services:
  Verify Services: `kubectl get svc -n prometheus`
  Edit Service: Change `type: ClusterIP` to `LoadBalancer` for external access.

---

## Security Best Practices

### Vulnerability Scanning

Tool: Uses Trivy (or similar) to scan Docker images for known vulnerabilities. Pipeline fails if vulnerabilities are detected (`--exit-code 1`).

### Dependency Checks

Tool: Uses Snyk (or similar) to check for vulnerabilities in project dependencies.

### Configuration Validation

Tool: Uses kubeval to validate Kubernetes manifests against Kubernetes schemas.

### Requirements

Trivy: Ensure Trivy is installed and available on Jenkins agents.
Snyk: Install Snyk CLI and authenticate if necessary.
Kubeval: Install kubeval on Jenkins agents for validating Kubernetes manifests.

---

## Manual Steps for Development and Testing

### Prerequisites

Install Kubectl: [Kubectl Installation Guide](https://kubernetes.io/docs/tasks/tools/)
Install Helm: [Helm Installation Guide](https://helm.sh/docs/intro/install/)
  ```bash
  helm repo update
  ```
Install/Update AWS CLI: [AWS CLI Installation Guide](https://aws.amazon.com/cli/) (Install v2 only)

### Kubernetes Context

Update Kubernetes Context:
  ```bash
  aws eks update-kubeconfig --name my-eks-cluster --region us-west-2
  ```
Verify Access:
  ```bash
  kubectl auth can-i "*" "*"
  kubectl get nodes
  ```
Verify Autoscaler:
  ```bash
  kubectl get pods -n kube-system
  ```
Check Autoscaler Logs:
  ```bash
  kubectl logs -f -n kube-system -l app=cluster-autoscaler
  ```
Check Load Balancer Logs:
  ```bash
  kubectl logs -f -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
  ```

### Docker Images

Build Front End:
  ```bash
  docker build -t workshop-frontend:v1 .
  docker tag workshop-frontend:v1 public.ecr.aws/w8u5e4v2/workshop-frontend:v1
  docker push public.ecr.aws/w8u5e4v2/workshop-frontend:v1
  ```
Build Back End:
  ```bash
  docker build -t workshop-backend:v1 .
  docker tag workshop-backend:v1 public.ecr.aws/w8u5e4v2/workshop-backend:v1
  docker push public.ecr.aws/w8u5e4v2/workshop-backend:v1
  ```

### Update Kubeconfig

Update Command:
  ```bash
  aws eks update-kubeconfig --region us-west-2 --name my-eks-cluster
  ```

### Kubernetes Resources

Create Namespace:
  ```bash
  kubectl create ns workshop
  kubectl config set-context --current --namespace workshop
  ```

MongoDB Setup:
  ```bash
  cd k8s_manifests/mongo_v1
  kubectl apply -f secrets.yaml
  kubectl apply -f deploy.yaml
  kubectl apply -f service.yaml
  ```

Backend API Setup:
  ```bash
  kubectl apply -f backend-deployment.yaml
  kubectl apply -f backend-service.yaml
  ```

Frontend Setup:
  ```bash
  kubectl apply -f frontend-deployment.yaml
  kubectl apply -f frontend-service.yaml
  ```

Create Load Balancer:
  ```bash
  kubectl apply -f full_stack_lb.yaml
  ```

### Troubleshooting

Check Pod Logs:
  ```bash
  kubectl logs -f POD_ID -f
  ```

### Grafana Setup

Verify Services:
  ```bash
  kubectl get svc -n prometheus
  ```
Edit Service:
  ```bash
  kubectl edit svc prometheus-grafana -n prometheus
  ```

### Cleanup

Destroy Kubernetes Resources:
  ```bash
  cd ./k8s_manifests
  kubectl delete -f -f
  ```

Remove AWS Resources:
  ```bash
  cd terraform
  terraform destroy --auto-approve
  ```

