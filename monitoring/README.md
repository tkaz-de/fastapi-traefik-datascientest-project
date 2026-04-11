# Monitoring (Prometheus + Grafana + Alertmanager)

This repository supports monitoring in two required operating models:

1. **Local/Compose** for development and tests.
2. **Kubernetes-compatible** via manifests in `k8s/monitoring`.

## 1) K8s Operating Model (required for cluster operation)

In the current single-VM implementation, this K8s operating model runs on Minikube. `dev` and `prod` are separated by namespace.

The following manifests provide the monitoring stack:

- `k8s/monitoring/monitoring-namespace.yaml`
- `k8s/monitoring/prometheus-config.yaml`
- `k8s/monitoring/prometheus-deployment.yaml`
- `k8s/monitoring/blackbox-exporter.yaml`
- `k8s/monitoring/alertmanager.yaml`
- `k8s/monitoring/grafana.yaml`
- `k8s/monitoring/grafana-dashboards.yaml`

### Deployment

```bash
kubectl apply -f k8s/monitoring/monitoring-namespace.yaml
kubectl apply -f k8s/monitoring/blackbox-exporter.yaml
kubectl apply -f k8s/monitoring/alertmanager.yaml
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-dashboards.yaml
kubectl apply -f k8s/monitoring/grafana.yaml
```

### Operating Procedure (runbook baseline)

1. **Deploy the stack** using the commands above.
2. **Check targets** in Prometheus (`/targets`): `prometheus`, `backend`, and `blackbox-db` must be `UP`.
3. **Check alerts** in Prometheus (`/alerts`) and Alertmanager (`/#/alerts`).
4. **Check dashboards** in Grafana (datasource present, dashboard imported/available).
5. **Test alerting** by briefly stopping the backend service and triggering `BackendDown`.

## 2) Metric Sources

### Application Metrics (FastAPI Backend)

Source: `GET /metrics` on the backend.

Examples:
- `app_http_requests_total{method,path,status}`
- `app_http_requests_sum`
- `app_uptime_seconds`

### Infrastructure / Reachability Metrics

- `up{job="backend"}` aus Prometheus-Scrape.
- `probe_success{job="blackbox-db"}` from Blackbox Exporter (TCP check against the PostgreSQL endpoint).

## 3) Baseline Alerts (required)

The alert rules are defined in `k8s/monitoring/prometheus-config.yaml` and cover at least:

1. **Availability**: `BackendDown`
2. **Error rate**: `BackendHighErrorRate` (5xx ratio > 5% over 10 minutes)
3. **Restart spikes**: `BackendRestartSpike` (frequent uptime resets)
4. **Database reachability**: `DatabaseUnreachable` (failed TCP probe)

## 4) Dashboards

- Standard-Dashboard-Datei: `monitoring/grafana/dashboards/backend-overview.json`
- Provisioning-Dateien:
  - `monitoring/grafana/provisioning/datasources/datasource.yml`
  - `monitoring/grafana/provisioning/dashboards/dashboards.yml`

In the Kubernetes setup, Grafana is provisioned with the Prometheus datasource and the `Backend Overview` dashboard. The dashboard is mounted from `k8s/monitoring/grafana-dashboards.yaml` to `/var/lib/grafana/dashboards/backend-overview.json`.

## 5) Alert Routing

Alertmanager is configured as the central router:

- **default** → `http://alert-router.monitoring.svc.cluster.local:8080/alerts/default`
- **critical** → `http://alert-router.monitoring.svc.cluster.local:8080/alerts/critical`

Recommended `alert-router` integrations:
- `default`: team channel (for example Slack/Teams)
- `critical`: on-call/pager (for example PagerDuty/Opsgenie)

This documents the escalation paths and anchors them technically in the Alertmanager configuration.

## 6) Local Operation with Docker Compose

For local development:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

Verify:
- Backend-Metriken: `curl http://localhost:8000/metrics`
- Prometheus Targets: `http://localhost:9090/targets`
- Grafana: `http://localhost:3000` (`admin` / `admin`)
