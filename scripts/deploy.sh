#!/usr/bin/env bash
# Deploys app + Redis + Prometheus + Grafana. Run: sudo bash scripts/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] || cp .env.example .env   # automated environment variable configuration
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build
sleep 10
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
echo "Health check:"
curl -s http://localhost:8000/health
echo
