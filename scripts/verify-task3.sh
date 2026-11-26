#!/usr/bin/env bash
# Task 03 proof: build, size, non-root, health, volume persistence. Run: sudo bash scripts/verify-task3.sh
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p docs/logs
{
  echo "===== 1. MULTI-STAGE BUILD ====="
  docker compose build --no-cache --progress=plain
  echo
  echo "===== 2. IMAGE SIZE (must be < 150MB) ====="
  docker images devops-capstone-web
  echo
  echo "===== 3. NON-ROOT USER CHECK ====="
  docker compose run --rm --no-deps web id
  echo
  echo "===== 4. START STACK ====="
  docker compose up -d
  sleep 15
  docker compose ps
  echo
  echo "===== 5. HEALTH CHECK ====="
  curl -s localhost:8000/health
  echo
  docker inspect --format '{{.Name}} health={{.State.Health.Status}}' capstone-web capstone-redis
  echo
  echo "===== 6. COUNTER BEFORE RESTART ====="
  curl -s localhost:8000/
  curl -s localhost:8000/
  echo
  echo "===== 7. FULL RESTART (containers removed, volume kept) ====="
  docker compose down
  docker compose up -d
  sleep 15
  echo
  echo "===== 8. COUNTER AFTER RESTART (must continue, not reset to 1) ====="
  curl -s localhost:8000/
} 2>&1 | tee docs/logs/task3-build-and-test.log
