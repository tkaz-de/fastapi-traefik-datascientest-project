# Monitoring (Prometheus + Grafana + Alertmanager)

Dieses Repository unterstützt Monitoring in zwei verbindlichen Betriebsmodellen:

1. **Lokal/Compose** für Entwicklung und Tests.
2. **Kubernetes-kompatibel** über Manifeste in `k8s/monitoring`.

## 1) K8s-Betriebsmodell (verbindlich für Cluster-Betrieb)

Im aktuell umgesetzten Ein-VM-Nachweis läuft dieses K8s-Betriebsmodell auf Minikube. `dev` und `prod` sind dabei per Namespace getrennt.

Die folgenden Manifeste stellen den Monitoring-Stack bereit:

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

### Betriebsablauf (Runbook-Basis)

1. **Stack ausrollen** (Befehle oben).
2. **Targets prüfen** in Prometheus (`/targets`): `prometheus`, `backend`, `blackbox-db` müssen `UP` sein.
3. **Alerts prüfen** in Prometheus (`/alerts`) und Alertmanager (`/#/alerts`).
4. **Dashboards prüfen** in Grafana (Datasource vorhanden, Dashboard importiert/verfügbar).
5. **Alarmierung testen** (z. B. Backend-Service kurzfristig stoppen und `BackendDown` auslösen).

## 2) Metrikquellen

### Applikationsmetriken (FastAPI Backend)

Quelle: `GET /metrics` im Backend.

Beispiele:
- `app_http_requests_total{method,path,status}`
- `app_http_requests_sum`
- `app_uptime_seconds`

### Infrastruktur-/Erreichbarkeitsmetriken

- `up{job="backend"}` aus Prometheus-Scrape.
- `probe_success{job="blackbox-db"}` aus Blackbox Exporter (TCP-Check auf PostgreSQL-Endpunkt).

## 3) Basis-Alerts (verbindlich)

Die Alert-Regeln liegen in `k8s/monitoring/prometheus-config.yaml` und decken mindestens ab:

1. **Verfügbarkeit**: `BackendDown`
2. **Error-Rate**: `BackendHighErrorRate` (5xx-Anteil > 5% über 10 Minuten)
3. **Restart-Spikes**: `BackendRestartSpike` (häufige Uptime-Resets)
4. **DB-Erreichbarkeit**: `DatabaseUnreachable` (TCP-Probe fehlgeschlagen)

## 4) Dashboards

- Standard-Dashboard-Datei: `monitoring/grafana/dashboards/backend-overview.json`
- Provisioning-Dateien:
  - `monitoring/grafana/provisioning/datasources/datasource.yml`
  - `monitoring/grafana/provisioning/dashboards/dashboards.yml`

Im Kubernetes-Setup wird Grafana mit Prometheus-Datasource und `Backend Overview` Dashboard provisioniert. Das Dashboard wird aus `k8s/monitoring/grafana-dashboards.yaml` nach `/var/lib/grafana/dashboards/backend-overview.json` gemountet.

## 5) Alarmwege

Alertmanager ist als zentraler Router vorgesehen:

- **default** → `http://alert-router.monitoring.svc.cluster.local:8080/alerts/default`
- **critical** → `http://alert-router.monitoring.svc.cluster.local:8080/alerts/critical`

Empfohlene Anbindung des `alert-router`:
- `default`: Team-Kanal (z. B. Slack/Teams)
- `critical`: On-Call/Pager (z. B. PagerDuty/Opsgenie)

Damit sind Eskalationspfade dokumentiert und technisch in der Alertmanager-Konfiguration verankert.

## 6) Lokaler Betrieb mit Docker Compose

Für lokale Entwicklung:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

Prüfen:
- Backend-Metriken: `curl http://localhost:8000/metrics`
- Prometheus Targets: `http://localhost:9090/targets`
- Grafana: `http://localhost:3000` (`admin` / `admin`)
