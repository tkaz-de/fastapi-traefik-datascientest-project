#!/usr/bin/env bash

set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_name="${CI_COMPOSE_PROJECT_NAME:-ci-backend}"
coverage_title="${1:-Coverage for local-ci}"

cd "$repo_root"

dc() {
  docker compose -p "$project_name" "$@"
}

cleanup() {
  dc down -v --remove-orphans >/dev/null 2>&1 || true
}

trap cleanup EXIT

docker network inspect traefik-public >/dev/null 2>&1 || docker network create traefik-public >/dev/null

mkdir -p backend/htmlcov

dc down -v --remove-orphans >/dev/null 2>&1 || true
dc up -d db
dc run --build --rm prestart
dc run --build --rm -v "$repo_root/backend/htmlcov:/app/htmlcov" backend \
  bash scripts/tests-start.sh "$coverage_title"
