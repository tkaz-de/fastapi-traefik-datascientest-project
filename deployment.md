# FastAPI Project - Deployment

## Maintained Path

The maintained delivery path for this repository is:

- one VM
- Minikube on that VM
- Kubernetes namespaces `dev` and `prod`
- GHCR for registry
- GitHub Actions for CI/CD

The older Docker Compose and Traefik instructions below remain useful as legacy or fallback material, but they are not the primary path used to satisfy the current project requirements.

## Single-VM Minikube Deployment

For the implemented requirement path on one VM:

1. Install or place `minikube` on the VM.
2. Start Minikube with Docker driver:

```bash
minikube start --driver=docker --cpus=2 --memory=3072 --addons=ingress
```

3. Apply namespaces and manifests:

```bash
kubectl apply -f k8s/dev
kubectl apply -f k8s/prod
```

4. For local Minikube verification, the ingress resources must target the local NGINX ingress controller.
5. For single-node local verification, `prod` may run with one application replica to fit VM capacity.

## Implemented DR Components

The current Kubernetes manifests now include:

- persistent database storage in `dev` and `prod`
- dedicated backup PVCs in `dev` and `prod`
- daily PostgreSQL backup CronJobs in `dev` and `prod`

Relevant manifests:

- `k8s/dev/postgres-dev.yaml`
- `k8s/prod/postgres-prod.yaml`

You can deploy the project using Docker Compose to a remote server.

This project expects you to have a Traefik proxy handling communication to the outside world and HTTPS certificates.

You can use CI/CD (continuous integration and continuous deployment) systems to deploy automatically, there are already configurations to do it with GitHub Actions.

But you have to configure a couple things first. 🤓

## Preparation

* Have a remote server ready and available.
* Configure the DNS records of your domain to point to the IP of the server you just created.
* Configure a wildcard subdomain for your domain, so that you can have multiple subdomains for different services, e.g. `*.fastapi-project.example.com`. This will be useful for accessing different components, like `dashboard.fastapi-project.example.com`, `api.fastapi-project.example.com`, `traefik.fastapi-project.example.com`, `adminer.fastapi-project.example.com`, etc. And also for `staging`, like `dashboard.staging.fastapi-project.example.com`, `adminer.staging..fastapi-project.example.com`, etc.
* Install and configure [Docker](https://docs.docker.com/engine/install/) on the remote server (Docker Engine, not Docker Desktop).

## Public Traefik

We need a Traefik proxy to handle incoming connections and HTTPS certificates.

You need to do these next steps only once.

### Traefik Docker Compose

* Create a remote directory to store your Traefik Docker Compose file:

```bash
mkdir -p /root/code/traefik-public/
```

Copy the Traefik Docker Compose file to your server. You could do it by running the command `rsync` in your local terminal:

```bash
rsync -a docker-compose.traefik.yml root@your-server.example.com:/root/code/traefik-public/
```

### Traefik Public Network

This Traefik will expect a Docker "public network" named `traefik-public` to communicate with your stack(s).

This way, there will be a single public Traefik proxy that handles the communication (HTTP and HTTPS) with the outside world, and then behind that, you could have one or more stacks with different domains, even if they are on the same single server.

To create a Docker "public network" named `traefik-public` run the following command in your remote server:

```bash
docker network create traefik-public
```

### Traefik Environment Variables

The Traefik Docker Compose file expects some environment variables to be set in your terminal before starting it. You can do it by running the following commands in your remote server.

* Create the username for HTTP Basic Auth, e.g.:

```bash
export USERNAME=admin
```

* Create an environment variable with the password for HTTP Basic Auth, e.g.:

```bash
export PASSWORD=changethis
```

* Use openssl to generate the "hashed" version of the password for HTTP Basic Auth and store it in an environment variable:

```bash
export HASHED_PASSWORD=$(openssl passwd -apr1 $PASSWORD)
```

To verify that the hashed password is correct, you can print it:

```bash
echo $HASHED_PASSWORD
```

* Create an environment variable with the domain name for your server, e.g.:

```bash
export DOMAIN=fastapi-project.example.com
```

* Create an environment variable with the email for Let's Encrypt, e.g.:

```bash
export EMAIL=admin@example.com
```

**Note**: you need to set a different email, an email `@example.com` won't work.

### Start the Traefik Docker Compose

Go to the directory where you copied the Traefik Docker Compose file in your remote server:

```bash
cd /root/code/traefik-public/
```

Now with the environment variables set and the `docker-compose.traefik.yml` in place, you can start the Traefik Docker Compose running the following command:

```bash
docker compose -f docker-compose.traefik.yml up -d
```

## Deploy the FastAPI Project

Now that you have Traefik in place you can deploy your FastAPI project with Docker Compose.

**Note**: You might want to jump ahead to the section about Continuous Deployment with GitHub Actions.

## Environment Variables

You need to set some environment variables first.

Set the `ENVIRONMENT`, by default `local` (for development), but when deploying to a server you would put something like `staging` or `production`:

```bash
export ENVIRONMENT=production
```

Set the `DOMAIN`, by default `localhost` (for development), but when deploying you would use your own domain, for example:

```bash
export DOMAIN=fastapi-project.example.com
```

You can set several variables, like:

* `PROJECT_NAME`: The name of the project, used in the API for the docs and emails.
* `STACK_NAME`: The name of the stack used for Docker Compose labels and project name, this should be different for `staging`, `production`, etc. You could use the same domain replacing dots with dashes, e.g. `fastapi-project-example-com` and `staging-fastapi-project-example-com`.
* `BACKEND_CORS_ORIGINS`: A list of allowed CORS origins separated by commas.
* `SECRET_KEY`: The secret key for the FastAPI project, used to sign tokens.
* `FIRST_SUPERUSER`: The email of the first superuser, this superuser will be the one that can create new users.
* `FIRST_SUPERUSER_PASSWORD`: The password of the first superuser.
* `SMTP_HOST`: The SMTP server host to send emails, this would come from your email provider (E.g. Mailgun, Sparkpost, Sendgrid, etc).
* `SMTP_USER`: The SMTP server user to send emails.
* `SMTP_PASSWORD`: The SMTP server password to send emails.
* `EMAILS_FROM_EMAIL`: The email account to send emails from.
* `POSTGRES_SERVER`: The hostname of the PostgreSQL server. You can leave the default of `db`, provided by the same Docker Compose. You normally wouldn't need to change this unless you are using a third-party provider.
* `POSTGRES_PORT`: The port of the PostgreSQL server. You can leave the default. You normally wouldn't need to change this unless you are using a third-party provider.
* `POSTGRES_PASSWORD`: The Postgres password.
* `POSTGRES_USER`: The Postgres user, you can leave the default.
* `POSTGRES_DB`: The database name to use for this application. You can leave the default of `app`.
* `SENTRY_DSN`: The DSN for Sentry, if you are using it.

## GitHub Actions Environment Variables

There are some environment variables only used by GitHub Actions that you can configure:

* `LATEST_CHANGES`: Used by the GitHub Action [latest-changes](https://github.com/tiangolo/latest-changes) to automatically add release notes based on the PRs merged. It's a personal access token, read the docs for details.
* `SMOKESHOW_AUTH_KEY`: Used to handle and publish the code coverage using [Smokeshow](https://github.com/samuelcolvin/smokeshow), follow their instructions to create a (free) Smokeshow key.

### Generate secret keys

Some environment variables in the `.env` file have a default value of `changethis`.

You have to change them with a secret key, to generate secret keys you can run the following command:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Copy the content and use that as password / secret key. And run that again to generate another secure key.

### Deploy with Docker Compose

With the environment variables in place, you can deploy with Docker Compose:

```bash
docker compose -f docker-compose.yml up -d
```

For production you wouldn't want to have the overrides in `docker-compose.override.yml`, that's why we explicitly specify `docker-compose.yml` as the file to use.

## Continuous Deployment (CD)

You can use GitHub Actions to deploy your project automatically. 😎

You can have multiple environment deployments.

There are already two environments configured, `staging` and `production`. 🚀

### Install GitHub Actions Runner

* On your remote server, create a user for your GitHub Actions:

```bash
sudo adduser github
```

* Add Docker permissions to the `github` user:

```bash
sudo usermod -aG docker github
```

* Temporarily switch to the `github` user:

```bash
sudo su - github
```

* Go to the `github` user's home directory:

```bash
cd
```

* [Install a GitHub Action self-hosted runner following the official guide](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners#adding-a-self-hosted-runner-to-a-repository).

* When asked about labels, add a label for the environment, e.g. `production`. You can also add labels later.

After installing, the guide would tell you to run a command to start the runner. Nevertheless, it would stop once you terminate that process or if your local connection to your server is lost.

To make sure it runs on startup and continues running, you can install it as a service. To do that, exit the `github` user and go back to the `root` user:

```bash
exit
```

After you do it, you will be on the previous user again. And you will be on the previous directory, belonging to that user.

Before being able to go the `github` user directory, you need to become the `root` user (you might already be):

```bash
sudo su
```

* As the `root` user, go to the `actions-runner` directory inside of the `github` user's home directory:

```bash
cd /home/github/actions-runner
```

* Install the self-hosted runner as a service with the user `github`:

```bash
./svc.sh install github
```

* Start the service:

```bash
./svc.sh start
```

* Check the status of the service:

```bash
./svc.sh status
```

You can read more about it in the official guide: [Configuring the self-hosted runner application as a service](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service).

### Set Secrets

On your repository, configure secrets for the environment variables you need, the same ones described above, including `SECRET_KEY`, etc. Follow the [official GitHub guide for setting repository secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository).

The current Github Actions workflows expect these secrets:

* `DOMAIN_PRODUCTION`
* `DOMAIN_STAGING`
* `STACK_NAME_PRODUCTION`
* `STACK_NAME_STAGING`
* `EMAILS_FROM_EMAIL`
* `FIRST_SUPERUSER`
* `FIRST_SUPERUSER_PASSWORD`
* `POSTGRES_PASSWORD`
* `SECRET_KEY`
* `LATEST_CHANGES`
* `SMOKESHOW_AUTH_KEY`

## GitHub Action Deployment Workflows

There are GitHub Action workflows in the `.github/workflows` directory already configured for deploying to the environments (GitHub Actions runners with the labels):

* `staging`: after pushing (or merging) to the branch `master`.
* `production`: after publishing a release.

If you need to add extra environments you could use those as a starting point.

## URLs

Replace `fastapi-project.example.com` with your domain.

### Main Traefik Dashboard

Traefik UI: `https://traefik.fastapi-project.example.com`

### Production

Frontend: `https://dashboard.fastapi-project.example.com`

Backend API docs: `https://api.fastapi-project.example.com/docs`

Backend API base URL: `https://api.fastapi-project.example.com`

Adminer: `https://adminer.fastapi-project.example.com`

### Staging

Frontend: `https://dashboard.staging.fastapi-project.example.com`

Backend API docs: `https://api.staging.fastapi-project.example.com/docs`

Backend API base URL: `https://api.staging.fastapi-project.example.com`

Adminer: `https://adminer.staging.fastapi-project.example.com`

## Secret Management (per environment)

Do **not** commit real secrets into Git. Use templates and inject values at deploy time.

### 1) Local development

- Keep real values only in a non-versioned `.env` file.
- Use `.env.example` as template.
- Generate new secure values with:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 2) GitHub Actions / CI

Store sensitive values in **GitHub Secrets** (Repository or Environment level), e.g.:

- `SECRET_KEY`
- `FIRST_SUPERUSER_PASSWORD`
- `POSTGRES_PASSWORD`
- `PROXMOX_API_TOKEN`

Pass Terraform sensitive inputs via environment variables (`TF_VAR_*`), for example:

```bash
export TF_VAR_proxmox_endpoint="https://pve.example.com:8006/"
export TF_VAR_proxmox_api_token="$PROXMOX_API_TOKEN"
export TF_VAR_vm_clone_ssh_public_key="$VM_CLONE_SSH_PUBLIC_KEY"
```

### 3) Kubernetes

- Use `k8s/dev/backend-secret.example.yaml` as template only.
- Preferred production workflow: **Sealed Secrets** (or external secret manager).
- Commit only encrypted `SealedSecret` manifests, never plain `Secret` values.

Example workflow (Bitnami Sealed Secrets):

1. Create a local `Secret` manifest from template with real values.
2. Encrypt it with `kubeseal` against cluster public cert.
3. Commit only the generated `SealedSecret` YAML.
4. Apply in cluster; controller recreates runtime `Secret`.

### 4) Credential rotation (required after cleanup)

Because previous plaintext values were present in repository history, rotate outside the repo immediately:

- DB password
- API/Proxmox token
- `SECRET_KEY`
- first superuser password

After rotation, update only secret stores (GitHub Secrets, vault, Kubernetes sealed secret inputs), not tracked files.

## Kubernetes-Umgebungen `dev` vs. `prod`

Die Kubernetes-Manifeste sind jetzt strikt getrennt unter:

- `k8s/dev/` für Branch-Deployments aus `dev`
- `k8s/prod/` für Release-Deployments (`release.published`)

### Unterschiede in Variablen und Werten

| Bereich | Dev (`k8s/dev`) | Prod (`k8s/prod`) |
|---|---|---|
| Namespace | `dev` | `prod` |
| Backend Image (Manifest-Default) | `...-backend:dev` | `...-backend:prod` |
| Frontend Image (Manifest-Default) | `...-frontend:dev` | `...-frontend:prod` |
| Deployment Replikate | Backend `1`, Frontend `1` | Backend `3`, Frontend `3` |
| Backend Limits | `500m` CPU / `512Mi` RAM | `1000m` CPU / `1Gi` RAM |
| Backend Requests | `250m` CPU / `256Mi` RAM | `500m` CPU / `512Mi` RAM |
| Frontend Limits | `250m` CPU / `256Mi` RAM | `500m` CPU / `512Mi` RAM |
| Frontend Requests | `100m` CPU / `128Mi` RAM | `250m` CPU / `256Mi` RAM |
| `ENVIRONMENT` | `development` | `production` |
| `DOMAIN` | `dev.fastapi.local` | `api.example.com` |
| `POSTGRES_SERVER` | `db-dev` | `db-prod` |
| Secret `DATABASE_URL` Host | `db-dev` | `db-prod` |
| Secret `APP_ENV` | `development` | `production` |
| Ingress Host | `dev.fastapi.local` | `app.example.com` |
| Ingress Entrypoint | `web` | `websecure` |

### Label- und Selector-Konvention

In beiden Umgebungen werden konsistent diese Labels verwendet:

- `app.kubernetes.io/name: fastapi-traefik-datascientest-project`
- `app.kubernetes.io/component: backend|frontend|edge`
- `app.kubernetes.io/part-of: platform`
- `app.kubernetes.io/environment: dev|prod`
- `app.kubernetes.io/managed-by: github-actions`

Die `spec.selector.matchLabels` in Deployments und die Service-Selector referenzieren denselben Label-Satz (`name`, `component`, `environment`), sodass Pod-Discovery zwischen den Umgebungen deterministisch bleibt.

### CI/CD-Zielzuordnung

- Workflow `.github/workflows/deploy-dev.yml` rollt **nur** bei Push auf Branch `dev` nach Namespace `dev` aus.
- Workflow `.github/workflows/deploy-production.yml` rollt **nur** bei `release.published` nach Namespace `prod` aus.
- Beide Workflows wenden zuerst die jeweiligen Verzeichnis-Manifeste (`k8s/dev` oder `k8s/prod`) an und aktualisieren danach die Images per Tag (`sha` für dev, Release-Tag für prod).

## Disaster Recovery (DR) – Runbooks

Dieses Kapitel definiert verbindliche Runbooks für Ausfälle in Kubernetes- und Infrastruktur-Betrieb.

### 1) Backup-Strategie (Datenbank + Persistent Volumes)

#### 1.1 PostgreSQL-Backups

- **Täglich 02:00 UTC**: logischer Full-Backup via `pg_dump` (komprimiert).
- **Alle 15 Minuten**: WAL-Archivierung für Point-in-Time-Recovery (PITR).
- **Aufbewahrung**:
  - Tages-Backups: **14 Tage**
  - Wochen-Backups (Sonntag): **8 Wochen**
  - Monats-Backups (1. Tag): **12 Monate**
- **Ablage**: externer Objektspeicher (S3-kompatibel) mit Bucket-Versionierung und Server-Side-Encryption.
- **Integritätsprüfung**: nach jedem Upload Checksum-Verifikation (z. B. SHA256) und Job-Status in Monitoring.

Beispiel-Kommandos (ausgeführt durch CronJob/Backup-Job):

```bash
pg_dump --format=custom --no-owner --no-privileges \
  --dbname="$DATABASE_URL" \
  | gzip > "/backup/db/app_$(date +%F_%H%M).dump.gz"
```

```bash
pg_restore --list "/backup/db/app_YYYY-MM-DD_HHMM.dump.gz" >/dev/null
```

#### 1.2 Persistent-Volume-Backups

- **Täglich 03:00 UTC**: Snapshot aller produktiven PVCs (Datei-Uploads, Reports, sonstige stateful Artefakte).
- **Aufbewahrung**:
  - tägliche Snapshots: **7 Tage**
  - wöchentliche Snapshots: **6 Wochen**
- **Technik**: CSI VolumeSnapshots oder Storage-Provider-Snapshots (je nach Cluster).
- **Wiederherstellungspunkt** wird pro Snapshot versioniert dokumentiert (Snapshot-ID + Timestamp).

#### 1.3 Restore-Tests (verpflichtend)

- **Monatlich (1x)**: vollständiger Restore-Test in isolierter `dr-test` Namespace/Umgebung.
- **Pro Quartal (1x)**: kombinierter Restore-Test (DB + PV + Anwendung) mit Smoke-Test.
- **Erfolgskriterium**: Applikation startet, Healthchecks OK, Login + kritischer Geschäftsvorgang erfolgreich.
- **Nachweis**: Protokoll mit Zeitpunkt, verwendeten Backups/Snapshots, Dauer und Ergebnis.

---

### 2) Recovery bei Pod-/Node-Ausfall inkl. RTO/RPO

#### 2.1 Zielwerte

- **Pod-Ausfall**: `RTO <= 10 Minuten`, `RPO <= 15 Minuten`
- **Node-Ausfall**: `RTO <= 30 Minuten`, `RPO <= 15 Minuten`
- **Region-/Cluster-kompletter Ausfall (falls nur Single-Cluster)**: `RTO <= 4 Stunden`, `RPO <= 24 Stunden`

#### 2.2 Runbook: Pod-Ausfall

1. **Alarm prüfen** (z. B. CrashLoopBackOff, OOMKilled, Readiness Fail).
2. Zustand erfassen:
   ```bash
   kubectl -n prod get pods -o wide
   kubectl -n prod describe pod <pod-name>
   kubectl -n prod logs <pod-name> --previous
   ```
3. Falls Konfig-/Secret-Fehler: korrigieren und Rollout neu starten.
   ```bash
   kubectl -n prod rollout restart deployment/backend
   ```
4. Verifizieren:
   ```bash
   kubectl -n prod rollout status deployment/backend --timeout=300s
   ```
5. API-/Frontend-Healthcheck prüfen und Incident schließen.

#### 2.3 Runbook: Node-Ausfall

1. Node als `NotReady` identifizieren:
   ```bash
   kubectl get nodes
   ```
2. Workloads sichern und neu verteilen:
   ```bash
   kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
   ```
3. Infrastruktur-Team behebt Node/VM/Host.
4. Node nach Reparatur wieder aufnehmen:
   ```bash
   kubectl uncordon <node-name>
   ```
5. Prüfen, ob Replikate + Stateful Workloads wieder stabil laufen:
   ```bash
   kubectl -n prod get pods -o wide
   ```

---

### 3) Rollback-Strategie

#### 3.1 Image-Tagging

- **Dev**: immutable Tag pro Commit-SHA (`:<git-sha>`).
- **Prod**: immutable Release-Tag (`:vX.Y.Z`) plus optional `:prod` als beweglicher Alias.
- Niemals auf mutable `:latest` für produktive Rollouts vertrauen.

#### 3.2 Kubernetes Rollback mit `kubectl`

1. Rollout-Historie prüfen:
   ```bash
   kubectl -n prod rollout history deployment/backend
   ```
2. Auf vorherige Revision zurück:
   ```bash
   kubectl -n prod rollout undo deployment/backend
   ```
3. Oder gezielt auf Revision:
   ```bash
   kubectl -n prod rollout undo deployment/backend --to-revision=<n>
   ```
4. Status + Smoke-Test:
   ```bash
   kubectl -n prod rollout status deployment/backend --timeout=300s
   ```

#### 3.3 Helm Rollback (wenn Helm genutzt wird)

```bash
helm -n prod history fastapi-app
helm -n prod rollback fastapi-app <revision>
helm -n prod status fastapi-app
```

---

### 4) IaC-Reprovisioning mit Terraform (ohne sensitive Daten im Code)

#### 4.1 Grundsätze

- Keine Secrets in `*.tf`, `*.tfvars` im Repo oder in Klartext-Outputs.
- Sensitive Werte ausschließlich über Secret Store/CI-Variablen (z. B. `TF_VAR_*`).
- Remote State (z. B. S3 + Locking via DynamoDB oder Terraform Cloud) verpflichtend für Teambetrieb.

#### 4.2 Runbook: Reprovisioning

1. **Terraform initialisieren**:
   ```bash
   terraform init -upgrade
   ```
2. **Format/Validierung**:
   ```bash
   terraform fmt -check
   terraform validate
   ```
3. **Plan erstellen** (mit env-basierten sensitiven Variablen):
   ```bash
   terraform plan -out=tfplan
   ```
4. **Plan prüfen (Vier-Augen-Prinzip)**.
5. **Apply exakt aus freigegebenem Plan**:
   ```bash
   terraform apply tfplan
   ```
6. **Post-Checks**: Ressourcenstatus, Netzwerkpfade, Cluster-Erreichbarkeit, App-Health.

#### 4.3 State-Handling

- Vor Änderungen:
  ```bash
  terraform state pull > "state-backup-$(date +%F_%H%M).json"
  ```
- Bei Drift:
  ```bash
  terraform plan -refresh-only
  ```
- Import bestehender Ressourcen:
  ```bash
  terraform import <resource_address> <provider_resource_id>
  ```
- Kein manuelles Editieren der State-Datei außer im formal freigegebenen Break-Glass-Prozess.
