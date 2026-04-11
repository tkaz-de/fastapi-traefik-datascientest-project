# FastAPI Full Stack DevOps Project

This repository demonstrates a production-style software delivery setup for a FastAPI backend, React frontend, PostgreSQL database, Docker-based packaging, Kubernetes deployment, GitHub Actions CI/CD, Terraform-based VM provisioning, monitoring, security scanning, and disaster recovery runbooks.

The implementation standard for this project is intentionally narrow:

- Container registry: `GitHub Container Registry (GHCR)`
- CI/CD: `GitHub Actions`
- Orchestration: `Kubernetes`
- Cluster target: `Minikube`
- Monitoring: `Prometheus + Grafana`
- Infrastructure as Code: `Terraform`
- Secret handling: `Kubernetes Secrets`
- Environments: `dev` and `prod`

Additional files for staging or alternative deployment paths may still exist in the repository, but the required and maintained delivery path is the one listed above.

## Application Overview

The platform contains:

- `backend/`: FastAPI API with database access, auth flows, metrics endpoint, and tests
- `frontend/`: React and TypeScript single-page app with unit and Playwright E2E tests
- `k8s/`: Kubernetes manifests for `dev`, `prod`, and monitoring
- `.github/workflows/`: CI, security, build, and deployment automation
- `main.tf`: Terraform for VM provisioning
- `ansible/`: Bootstrap automation for an additional Kubernetes-capable VM
- `monitoring/`: Prometheus and Grafana assets

## Architecture

The mandatory architecture diagram is available here:

- [img/architecture-overview.svg](/home/tkaz1/projects/fastapi-traefik-datascientest-project/img/architecture-overview.svg)

At a high level:

1. Developers push to `dev` or open pull requests.
2. GitHub Actions runs tests and security scans.
3. Docker images are built and pushed to GHCR.
4. The Kubernetes target runs on a single VM via Minikube, with `dev` and `prod` separated by namespaces.
5. The `dev` workflow deploys automatically to the Kubernetes `dev` namespace, while production uses an approval gate before rollout to `prod`.
6. Prometheus and Grafana observe the running workloads.
7. Terraform and Ansible reproduce the VM and cluster bootstrap path.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Backend | FastAPI, Python, SQLModel, Alembic |
| Frontend | React, TypeScript, Vite |
| Database | PostgreSQL |
| Containers | Docker, Docker Compose |
| Registry | GHCR |
| Kubernetes | Minikube, kubectl manifests |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus, Grafana, Alertmanager |
| Security | Trivy, CodeQL, Dependabot, Kubernetes Secrets, TLS ingress |
| IaC | Terraform |
| VM bootstrap | Ansible |

## Environment Model

The project is designed around two required environments:

- `dev`
  - branch-driven deployment target
  - automatic deployment from `dev`
  - lower replica counts and development-facing config
- `prod`
  - stable user-facing target
  - deployment only after approval
  - hardened ingress, RBAC, and higher replica counts in the general manifests

For the current single-VM Minikube implementation, `prod` is locally run with one application replica to fit the available node resources while preserving namespace separation and the production manifest structure.

Key environment differences are defined in:

- [k8s/dev/dev-config.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/dev/dev-config.yaml)
- [k8s/prod/prod-config.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/prod-config.yaml)
- [k8s/dev/backend-dev.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/dev/backend-dev.yaml)
- [k8s/prod/backend-prod.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/backend-prod.yaml)

## Running the Project Locally with Docker

Local development and smoke testing can run with Docker Compose:

```bash
docker compose up -d
```

Optional local monitoring:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

Relevant files:

- [docker-compose.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/docker-compose.yml)
- [docker-compose.monitoring.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/docker-compose.monitoring.yml)

## Docker Images

Both application components are containerized:

- Backend image: [backend/Dockerfile](/home/tkaz1/projects/fastapi-traefik-datascientest-project/backend/Dockerfile)
- Frontend image: [frontend/Dockerfile](/home/tkaz1/projects/fastapi-traefik-datascientest-project/frontend/Dockerfile)

The maintained registry target is GHCR under the current GitHub repository owner:

- `ghcr.io/<repository-owner>/fastapi-traefik-datascientest-project-backend`
- `ghcr.io/<repository-owner>/fastapi-traefik-datascientest-project-frontend`

## Kubernetes Deployment

The maintained Kubernetes manifests are organized by environment:

- `k8s/dev`
- `k8s/prod`
- `k8s/monitoring`

They include:

- Deployments
- Services
- ConfigMaps
- Secrets
- PersistentVolumeClaims
- Database backup CronJobs
- Ingress
- Production RBAC

Primary manifest entrypoints:

- [k8s/dev/dev-namespace.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/dev/dev-namespace.yaml)
- [k8s/prod/prod-namespace.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/prod-namespace.yaml)
- [k8s/dev/postgres-dev.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/dev/postgres-dev.yaml)
- [k8s/prod/postgres-prod.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/postgres-prod.yaml)
- [k8s/dev/traefik-ingress.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/dev/traefik-ingress.yaml)
- [k8s/prod/ingress-prod.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/ingress-prod.yaml)
- [k8s/prod/rbac-prod.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/rbac-prod.yaml)

Operational note:

- In the current local Minikube setup, the live cluster uses the NGINX ingress controller.
- The repository ingress manifests remain Traefik-oriented for the broader deployment path, and were patched live in-cluster for the single-VM Minikube verification.

## Tests

The repository contains multiple test layers:

- Backend API, CRUD, and script-level tests
- Frontend unit tests
- Frontend end-to-end tests with Playwright

Representative paths:

- [backend/app/tests/api/routes/test_users.py](/home/tkaz1/projects/fastapi-traefik-datascientest-project/backend/app/tests/api/routes/test_users.py)
- [backend/app/tests/crud/test_user.py](/home/tkaz1/projects/fastapi-traefik-datascientest-project/backend/app/tests/crud/test_user.py)
- [frontend/tests/unit/example.test.ts](/home/tkaz1/projects/fastapi-traefik-datascientest-project/frontend/tests/unit/example.test.ts)
- [frontend/tests/e2e/login.spec.ts](/home/tkaz1/projects/fastapi-traefik-datascientest-project/frontend/tests/e2e/login.spec.ts)

## CI/CD

The maintained pipeline path is:

1. Test the backend and frontend
2. Build Docker images
3. Push images to GHCR
4. Deploy `dev` automatically on branch `dev`
5. Deploy `prod` only after manual approval

Primary workflows:

- [deploy-dev.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/.github/workflows/deploy-dev.yml)
- [deploy-production.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/.github/workflows/deploy-production.yml)
- [security-scans.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/.github/workflows/security-scans.yml)
- [playwright.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/.github/workflows/playwright.yml)

Support workflows exist for focused validation, but the branching and deployment standard for the project is `dev -> prod`.

## Infrastructure as Code

Terraform provisions the VM layer. For the implemented requirement path, Kubernetes is currently demonstrated on a single VM via Minikube; the Terraform VM definitions remain available as the reproducible VM layer:

- [main.tf](/home/tkaz1/projects/fastapi-traefik-datascientest-project/main.tf)

Ansible assets for VM bootstrap remain available:

- [ansible/setup-vm.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/ansible/setup-vm.yml)
- [ansible/bootstrap-k8s-vm.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/ansible/bootstrap-k8s-vm.yml)
- [ansible/deploy-k8s-app.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/ansible/deploy-k8s-app.yml)
- [ansible/group_vars/fastapivm_test.example.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/ansible/group_vars/fastapivm_test.example.yml)

This keeps infrastructure reproducible instead of manually assembled.

## Monitoring

Monitoring is implemented with Prometheus and Grafana, with Alertmanager wiring documented and Kubernetes manifests included.

Main references:

- [monitoring/README.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/monitoring/README.md)
- [k8s/monitoring/prometheus-deployment.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/monitoring/prometheus-deployment.yaml)
- [k8s/monitoring/grafana.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/monitoring/grafana.yaml)

## Security Considerations

The maintained security controls include at least three required layers:

- Trivy image and filesystem scans
- CodeQL analysis
- Dependabot dependency monitoring
- Kubernetes Secrets for runtime secret injection
- TLS-only production ingress
- Production service accounts and reduced token exposure

Main references:

- [SECURITY.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/SECURITY.md)
- [.github/dependabot.yml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/.github/dependabot.yml)
- [k8s/prod/ingress-prod.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/ingress-prod.yaml)
- [k8s/prod/rbac-prod.yaml](/home/tkaz1/projects/fastapi-traefik-datascientest-project/k8s/prod/rbac-prod.yaml)

## Disaster Recovery

Disaster recovery is documented around:

- database backup and restore
- persistent storage backup expectations
- recovery from pod or node failure
- infrastructure re-provisioning from Terraform
- rollback to earlier deployment revisions

Main references:

- [DR.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/DR.md)
- [deployment.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/deployment.md)

The Kubernetes implementation now includes:

- persistent database volumes for `dev` and `prod`
- dedicated backup volumes for `dev` and `prod`
- daily PostgreSQL backup CronJobs in both namespaces

## Setup and Deployment References

Detailed operational documentation remains in:

- [deployment.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/deployment.md)
- [development.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/development.md)
- [backend/README.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/backend/README.md)
- [frontend/README.md](/home/tkaz1/projects/fastapi-traefik-datascientest-project/frontend/README.md)

## Verification

The current single-VM Minikube implementation has been verified with:

- `dev` and `prod` application workloads running in separate namespaces
- ingress-based frontend and backend health checks returning `200`
- Prometheus, Grafana, Alertmanager, and Blackbox Exporter running in `monitoring`
- Prometheus scrape targets `backend.dev`, `backend.prod`, `blackbox-db`, and `prometheus` reporting `up`
- Grafana datasource and `Backend Overview` dashboard provisioned from Kubernetes manifests
- PostgreSQL backup CronJobs present in `dev` and `prod`, with a successful manual backup job confirmed in `dev`
- backend test execution passing via `bash scripts/ci-backend-checks.sh`
- frontend unit tests passing via `npm run test:unit`

## Current Delivery Scope

This repository already contains more than the minimum requirement. The maintained target for full compliance is not to support every historical path, but to keep one coherent delivery story fully working:

- `dev` and `prod`
- GHCR
- GitHub Actions
- Kubernetes
- Terraform-provisioned VM(s)
- Prometheus and Grafana
