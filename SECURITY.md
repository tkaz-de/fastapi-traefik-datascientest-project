# Security Policy

Security is very important for this project and its community. 🔒

Learn more about it below. 👇

## Versions

The latest version or release is supported.

You are encouraged to write tests for your application and update your versions frequently after ensuring that your tests are passing. This way you will benefit from the latest features, bug fixes, and **security fixes**.

## Reporting a Vulnerability

If you think you found a vulnerability, and even if you are not fully sure, report it privately to the repository maintainers. Use GitHub's private vulnerability reporting flow if it is enabled for the repository; otherwise use a non-public maintainer contact channel. Please be as explicit as possible and include reproduction steps and example code where relevant.

## Public Discussions

Please restrain from publicly discussing a potential security vulnerability. 🙊

It's better to discuss privately and try to find a solution first, to limit the potential impact as much as possible.

---

Thanks for your help!

The community and I thank you for that. 🙇


## Automated Security Scanning Evidence

Security scans run in GitHub Actions workflow `.github/workflows/security-scans.yml` on:

- every push to `main` and `dev` (for backend/frontend/k8s/workflow changes),
- every pull request touching the same areas,
- every Monday at 03:00 UTC (scheduled baseline scan),
- manual trigger (`workflow_dispatch`).

### Active Scanners

1. **CodeQL** (`python`, `javascript-typescript`) for static code and dependency data-flow analysis.
2. **Trivy filesystem scan** for source dependencies, IaC misconfiguration, and secrets.
3. **Trivy image scan** for backend/frontend container images (OS + library vulnerabilities).

### Pipeline Fail Criteria

The pipeline is configured to **fail hard on CRITICAL findings** for Trivy jobs (`exit-code: 1`, `severity: CRITICAL`).

### Finding Handling Standard

- **CRITICAL:** merge/deploy blocked until fixed or formally risk-accepted with documented justification.
- **HIGH:** remediation in the next planned sprint (or faster for internet-facing attack paths).
- **MEDIUM/LOW:** tracked in backlog and remediated during regular dependency/runtime updates.

## Kubernetes Production Minimum Standard (RBAC + TLS)

For production (`k8s/prod`) the minimum standard is:

1. **Dedicated ServiceAccounts per workload** (backend/frontend), no default account usage.
2. **`automountServiceAccountToken: false`** for workloads that do not require Kubernetes API access.
3. **TLS-only Ingress routing** via Traefik `websecure` entrypoint.
4. **Ingress TLS section** with managed certificate secret (`secretName`) for the production host.
5. **No plaintext external exposure**; traffic terminates on HTTPS before reaching app services.
