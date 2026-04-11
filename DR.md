# Disaster Recovery (DR)

This document consolidates the DR requirements and links to the operational runbooks.

## Scope

- Backend API, frontend, database, Kubernetes resources
- CI/CD artifacts (container images in GHCR)
- Infrastructure configuration (Kubernetes manifests, Terraform)

## Goals

- Meet **RTO** and **RPO** targets defined by operational objectives.
- Recover through standardized, testable procedures.
- Maintain documented ownership and evidence.

## Primary Runbooks

1. **Backup & Restore PostgreSQL**
2. **Recovery from Pod/Node Failure including RTO/RPO**
3. **Cluster/Namespace Recovery from Git (GitOps-compatible)**
4. **Secret Rotation after a Security Incident**

The detailed step-by-step procedures are documented in `deployment.md`:

- [Disaster Recovery (DR) – Runbooks](./deployment.md#disaster-recovery-dr--runbooks)

## Artifacts & Responsibilities

- Kubernetes manifests: `k8s/dev`, `k8s/staging`, `k8s/prod`
- Infrastructure code: `main.tf`
- Security process: `SECURITY.md`
- Monitoring for recovery verification: `monitoring/README.md`
- Active DB persistence and backup jobs: `k8s/dev/postgres-dev.yaml`, `k8s/prod/postgres-prod.yaml`

## Verification

- Regular restore tests in non-production environments
- Documentation of test date, duration, outcome, and deviations
- Follow-up improvement actions in the release/operations cadence
