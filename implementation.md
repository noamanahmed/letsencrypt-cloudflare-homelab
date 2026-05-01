# Implementation Specification: Let's Encrypt + Cloudflare (Certbot Wrapper)

## 1. Objective

Build a shell-based automation tool (`lecf`) that:

* Uses certbot with Cloudflare DNS plugin
* Works without public IPv4 (DNS-01 challenge)
* Supports nginx and apache deployment
* Supports systemd timer and cron
* Is dockerizable
* Is idempotent and safe

---

## 2. Core Constraints

* Must use certbot (NOT acme.sh, NOT lego)
* Must support DNS-01 via Cloudflare API token
* Must run on minimal Linux (Debian/Alpine)
* Must fail fast and clearly
* Must not partially overwrite live certificates

---

## 3. CLI Interface

```
lecf run [nginx|apache]
lecf renew [nginx|apache]
lecf check
```

Behavior:

* `run` → issue or renew if needed
* `renew` → force renewal
* `check` → validate environment only

---

## 4. Environment Validation (MANDATORY)

Implemented in: `lib/validate.sh`

### 4.1 Root Check

```
if [ "$(id -u)" -ne 0 ]; then
  exit with error: "Must run as root"
fi
```

---

### 4.2 Required Tools Check

Must verify presence of:

* certbot
* openssl
* curl
* dig
* grep
* awk
* sed

Fail if missing.

---

### 4.3 Certbot Plugin Check

Ensure:

```
python3-certbot-dns-cloudflare
```

Check:

```
certbot plugins | grep cloudflare
```

---

## 5. Config System

File: `configs/example.env`

Loaded via:

```
source configs/example.env
```

### Required Variables:

```
DOMAIN=example.com
EMAIL=admin@example.com
CF_API_TOKEN=xxx

CERT_DIR=/etc/lecf/certs
WEBROOT_DIR=/var/www/html

RENEW_DAYS=30
PROPAGATION_SECONDS=30
```

---

## 6. Certificate Lifecycle

Implemented in: `lib/cert.sh`

### 6.1 Check Expiry

Command:

```
openssl x509 -enddate -noout -in cert.pem
```

Compare with current time.

---

### 6.2 Renewal Decision

If:

```
expiry < NOW + RENEW_DAYS
```

→ renew

---

### 6.3 Certbot Execution

Command:

```
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/lecf/cloudflare.ini \
  --non-interactive \
  --agree-tos \
  --email $EMAIL \
  -d $DOMAIN \
  -d *.$DOMAIN
```

---

### 6.4 Credentials File

Path:

```
/etc/lecf/cloudflare.ini
```

Content:

```
dns_cloudflare_api_token = <TOKEN>
```

Permissions:

```
chmod 600
```

---

## 7. Certificate Storage

Source of truth:

```
/etc/letsencrypt/live/<domain>/
```

Internal copy:

```
/etc/lecf/certs/<domain>/
```

Files:

* fullchain.pem
* privkey.pem

---

## 8. Deployment Layer

### 8.1 Nginx

Path:

```
/etc/nginx/ssl/<domain>/
```

Reload:

```
nginx -t && systemctl reload nginx
```

---

### 8.2 Apache

Path:

```
/etc/apache2/ssl/<domain>/
```

Reload:

```
apachectl configtest && systemctl reload apache2
```

---

### 8.3 Deployment Rules

* Copy only if changed (checksum)
* Use temp directory before overwrite
* Reload only if deployment succeeded

---

## 9. Hooks System

Directory:

```
hooks/post-renew.d/
```

Execution:

```
for file in hooks/post-renew.d/*; do
  bash "$file"
done
```

---

## 10. Logging

Format:

```
[INFO] message
[ERROR] message
[DEBUG] message
```

All scripts must use shared logger in `lib/util.sh`.

---

## 11. systemd Integration

### lecf.service

* Type: oneshot
* Runs: `lecf run nginx`

### lecf.timer

* Runs twice daily
* Persistent=true

---

## 12. Cron Fallback

```
0 */12 * * * /usr/local/bin/lecf run nginx
```

---

## 13. Dockerization

### 13.1 Base Image

Use:

* debian:stable-slim OR alpine:latest

---

### 13.2 Required Packages

Debian:

```
apt install certbot python3-certbot-dns-cloudflare curl dnsutils openssl
```

Alpine:

```
apk add certbot certbot-dns-cloudflare curl bind-tools openssl
```

---

### 13.3 Volume Mounts

Must support:

* /etc/letsencrypt
* /etc/lecf

---

### 13.4 Entrypoint

```
CMD ["sh", "/app/bin/lecf", "run"]
```

---

### 13.5 docker-compose

Service must:

* mount config
* mount cert directories
* run periodically OR manually

---

## 14. Error Handling

Rules:

* `set -euo pipefail` in all scripts
* Abort on any failure
* Do NOT reload services if cert failed

---

## 15. Networking Requirements

Must allow outbound:

* HTTPS (ACME + Cloudflare API)
* DNS (port 53)

No inbound required.

---

## 16. Security Requirements

* API token must NOT be world-readable
* Scripts must not echo secrets
* Use minimal permissions

---

## 17. Final Behavior

Command:

```
lecf run nginx
```

Must:

1. Validate environment
2. Load config
3. Check certificate expiry
4. Renew if needed
5. Deploy to nginx
6. Reload nginx safely
7. Exit cleanly

---

## END
