# Disaster Recovery (DR)

Dieses Dokument bündelt die DR-Anforderungen und verweist auf die operativen Runbooks.

## Scope

- Backend API, Frontend, Datenbank, Kubernetes-Ressourcen
- CI/CD-Artefakte (Container Images in GHCR)
- Infrastrukturkonfiguration (Kubernetes Manifeste, Terraform)

## Ziele

- **RTO** und **RPO** gemäß Betriebszielen einhalten.
- Wiederherstellung über standardisierte, testbare Abläufe.
- Dokumentierte Verantwortlichkeiten und Nachweise.

## Primäre Runbooks

1. **Backup & Restore PostgreSQL**
2. **Recovery bei Pod-/Node-Ausfall inkl. RTO/RPO**
3. **Cluster-/Namespace-Recovery aus Git (GitOps-kompatibel)**
4. **Secret-Rotation nach Security-Incident**

Die ausführlichen Schritt-für-Schritt-Anleitungen sind in `deployment.md` dokumentiert:

- [Disaster Recovery (DR) – Runbooks](./deployment.md#disaster-recovery-dr--runbooks)

## Artefakte & Verantwortlichkeiten

- Kubernetes Manifeste: `k8s/dev`, `k8s/staging`, `k8s/prod`
- Infrastrukturcode: `main.tf`
- Security-Prozess: `SECURITY.md`
- Monitoring für Recovery-Verifikation: `monitoring/README.md`
- Aktive DB-Persistenz und Backup-Jobs: `k8s/dev/postgres-dev.yaml`, `k8s/prod/postgres-prod.yaml`

## Verifikation

- Regelmäßige Restore-Tests in nicht-produktiven Umgebungen
- Dokumentation von Testdatum, Dauer, Ergebnis, Abweichungen
- Ableitung von Verbesserungsmaßnahmen in Release-/Ops-Rhythmus
