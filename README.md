# DevOps Capstone: Dockerized Flask + Redis with CI/CD, Nginx and Prometheus/Grafana

![CI/CD](https://github.com/YOUR_GITHUB_USERNAME/devops-capstone/actions/workflows/ci-cd.yml/badge.svg)

**Live endpoint:** https://YOUR_SERVER_IP/  (self-signed certificate, accept the browser warning)

## Architecture
```
Internet --> [UFW: 22/80/443] --> Nginx (SSL, gzip, rate limit, caching headers)
                                      |
                                      v  127.0.0.1:8000
                              Docker: web (Flask + Gunicorn, non-root)
                                      |
                                      v
                              Docker: redis (volume redis-data, persistent)

Docker: prometheus (scrapes web:8000/metrics, alert rules) --> grafana (dashboards)
```

## Project structure
```
app/                    Flask app, tests, requirements
Dockerfile              Multi-stage build (alpine, non-root, healthcheck)
docker-compose.yml      web + redis (with volume + health checks)
docker-compose.monitoring.yml   Prometheus + Grafana
.github/workflows/ci-cd.yml     CI/CD pipeline
nginx/nginx.conf        Reverse proxy config
monitoring/             Prometheus config, alert rules, Grafana datasource
scripts/                setup-server.sh, deploy.sh, verify-task3.sh
docs/                   Linux setup doc, logs, screenshots
```

## Task 03: Docker
- Multi-stage Dockerfile, final image well under 150MB, runs as non-root user `appuser` (uid 10001).
- Compose orchestrates web + Redis; both have health checks; Redis data persists in the `redis-data` volume.
- Proof: `docs/logs/task3-build-and-test.log`

## Task 04: CI/CD (GitHub Actions)
`.github/workflows/ci-cd.yml` runs on pull requests and pushes to `main`:
1. flake8 lint -> 2. pytest unit tests -> 3. build Docker image and push to GitHub Container Registry (`ghcr.io`) using the built-in `GITHUB_TOKEN` secret.

## Task 05: Linux + Nginx
See [docs/LINUX_SETUP.md](docs/LINUX_SETUP.md) and [nginx/nginx.conf](nginx/nginx.conf).

## Task 06: Cloud deployment and monitoring
1. Launch Ubuntu 24.04 EC2 instance (ports 22, 80, 443 open in security group).
2. `git clone` this repo, then:
   ```
   sudo bash scripts/setup-server.sh
   sudo bash scripts/deploy.sh
   ```
3. Environment variables come from `.env` (created automatically from `.env.example`).
4. Monitoring: Prometheus scrapes `/metrics` every 15s; alert rule `WebServiceDown` fires when `up == 0` for 30s; Grafana uses Prometheus as its data source. Prometheus (9090) and Grafana (3000) are bound to localhost and accessed via SSH tunnel:
   `ssh -L 3000:localhost:3000 -L 9090:localhost:9090 ubuntu@YOUR_SERVER_IP`
5. Health endpoint: `/health`; metrics: `/metrics`.

## Screenshots
Add to `docs/screenshots/`: green Actions run, `docker ps`, live URL, Prometheus targets/alerts, Grafana panel.
