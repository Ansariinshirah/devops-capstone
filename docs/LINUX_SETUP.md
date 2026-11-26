# Linux Server Configuration (Task 05)

Server: Ubuntu 24.04 LTS on AWS EC2. All steps below are automated by `scripts/setup-server.sh`.

## 1. Users, permissions and SSH hardening
- Created non-root user `deploy` (member of `docker` group only, no sudo) with the same SSH public key.
- `/etc/ssh/sshd_config.d/00-hardening.conf` sets:
  - `PasswordAuthentication no` -> only SSH keys work
  - `PermitRootLogin no`
  - `PubkeyAuthentication yes`
- Verify: `sudo sshd -T | grep -E "passwordauthentication|permitrootlogin"`

## 2. UFW firewall (only ports 22, 80, 443)
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```
Verify: `sudo ufw status verbose`

## 3. Nginx reverse proxy (`nginx/nginx.conf`)
- Proxies `https://SERVER` -> Docker app on `127.0.0.1:8000`
- gzip compression for JSON/text
- Cache headers: `/static/` cached 7 days, dynamic pages `no-cache`
- Rate limiting: 10 req/s per IP, burst 20 (returns HTTP 429)
- HTTP (80) redirects to HTTPS (443)

## 4. SSL/TLS
Self-signed certificate (sandbox) generated with openssl at `/etc/nginx/ssl/`.
For a real domain: `sudo certbot --nginx -d yourdomain.com` (Let's Encrypt).

## 5. Verification commands
```
sudo nginx -t
curl -skI http://localhost                                   # 301 redirect
curl -skI -H "Accept-Encoding: gzip" https://localhost/ | grep -i content-encoding
for i in $(seq 1 40); do curl -sk -o /dev/null -w "%{http_code} " https://localhost/; done   # 429 appears
```
