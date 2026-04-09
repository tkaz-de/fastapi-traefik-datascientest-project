# FastAPI Full Stack DevOps Project

## Project Overview

This project is a full-stack web application designed to simulate a production-ready software delivery environment using modern DevOps and cloud engineering practices.

The platform includes a FastAPI backend, React frontend, PostgreSQL database, containerization with Docker, orchestration with Kubernetes, CI/CD automation, infrastructure provisioning, monitoring, and security best practices.

---

## Architecture Overview

The application consists of the following core components:

* **Backend:** FastAPI-based REST API
* **Frontend:** React / TypeScript frontend application
* **Database:** PostgreSQL relational database
* **Containerization:** Docker images stored in GitHub Container Registry (GHCR)
* **Container Orchestration:** Kubernetes running on Minikube
* **Monitoring:** Prometheus + Grafana
* **Infrastructure:** Proxmox VM provisioned with Terraform / Ansible

---

## Kubernetes Deployment

The application is deployed and managed using Kubernetes on a Minikube cluster.

### Environment Separation

Two isolated namespaces are used:

* **dev** – Development environment
* **prod** – Production environment

### Kubernetes Components

Each application layer runs independently as a Kubernetes Deployment:

* Backend Deployment
* Frontend Deployment
* PostgreSQL Deployment

Kubernetes Services provide internal communication between application components.

Traefik is used as the ingress controller for external traffic routing into the cluster.

---

## CI/CD Pipeline

Deployment and testing are fully automated using GitHub Actions.

### Pipeline Process

1. Developer pushes code to repository
2. Automated tests are triggered
3. Docker images are built
4. Images are pushed to GitHub Container Registry
5. Kubernetes deployments are updated automatically

### Deployment Strategy

* Push to **dev** branch triggers development deployment
* Push/manual trigger for **main/prod** triggers production deployment

---

## Security Measures

Security has been implemented across multiple layers of the project.

### Secret Management

* Sensitive runtime configuration is managed using **Kubernetes Secrets**
* GitHub repository secrets secure deployment credentials and cluster access

### Secure CI/CD

* No hard-coded credentials in workflow files
* GitHub Secrets are used for secure secret injection

### Dependency Monitoring

* **GitHub Dependabot** monitors dependencies for outdated or vulnerable packages
* Covers:

  * GitHub Actions
  * Python dependencies
  * npm packages
  * Docker dependencies

---

## Monitoring & Observability

System health and performance are monitored using:

* **Prometheus** for metrics collection
* **Grafana** for dashboards and visualization

Metrics collected include:

* Node / VM metrics
* Kubernetes pod/container metrics
* Application performance metrics

---

## Infrastructure as Code

The virtual machine infrastructure is provisioned using Infrastructure as Code principles.

### Tools Used

* **Terraform** – VM provisioning / infrastructure setup
* **Ansible** – Configuration management / automation

The application is hosted on a Proxmox virtual machine environment.

---

## Project Goal

The goal of this project is to demonstrate a production-style MVP deployment pipeline and infrastructure setup using modern DevOps practices.

While Minikube is primarily intended for development/testing, this setup simulates a production-like Kubernetes environment for learning and portfolio purposes.

---

## Future Improvements

Potential future enhancements include:

* HTTPS / TLS termination
* Extended Kubernetes RBAC configuration
* Advanced vulnerability scanning (e.g. Trivy)
* Horizontal pod autoscaling
* Multi-node Kubernetes cluster

---

## Technology Stack Summary

| Layer          | Technology                    |
| -------------- | ----------------------------- |
| Backend        | FastAPI / Python              |
| Frontend       | React / TypeScript            |
| Database       | PostgreSQL                    |
| Containers     | Docker                        |
| Registry       | GitHub Container Registry     |
| Orchestration  | Kubernetes / Minikube         |
| CI/CD          | GitHub Actions                |
| Monitoring     | Prometheus / Grafana          |
| Infrastructure | Proxmox / Terraform / Ansible |

---

## Authors

Developed as part of a Data Engineering / DevOps Engineering training project.
