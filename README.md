# Let's Encrypt + Cloudflare Toolkit (Homelab)

**Repository:** [https://github.com/noamanahmed/letsencrypt-cloudflare-homelab](https://github.com/noamanahmed/letsencrypt-cloudflare-homelab)

A lightweight shell-based toolkit for automating Let's Encrypt SSL certificate issuance and renewal using Cloudflare DNS-01 validation—designed for homelabs, private networks, and systems without public IPv4, with built-in support for `nginx`, `apache`, `systemd` timers, `OpenRC` / `BusyBox crond` (Alpine Linux), and `Docker`.

## Features

- **No Public IPv4 needed:** Uses DNS-01 challenge via Cloudflare to validate identity.
- **Dependency Minimal & Alpine Compatible:** Pure Bash, uses `openssl x509 -checkend` (no GNU `date` / `coreutils` requirement).
- **Service Management Agnostic:** Supports `systemd` (`systemctl`), `OpenRC` (`rc-service`), and direct reload commands.
- **Idempotent:** Safe to run interactively, as a systemd service, cron, or Kubernetes job without interfering with live certificates unnecessarily.
- **Multiple Integrations:**
  - `Docker` + `docker-compose` (with shared certificate volumes for web server containers)
  - `Kubernetes` CronJobs (`k8s/cronjob.yaml`)
  - `Systemd` Timers (`systemd/lecf.timer`)
  - `OpenRC` & `BusyBox crond` (`cron/crontab.example`)

## Usage

### Interactive Mode

Simply specify an action and follow the interactive prompts for any missing configuration:
```bash
./bin/lecf
```

### Command-Line Arguments

You can run `lecf` statelessly or in an automated background task by passing arguments:
```bash
lecf run nginx --domain example.com --email admin@example.com --cf-api-token xxx
```
*Note: Make sure to replace `nginx` with `apache` if you use Apache.*

Available Flags:
- `--domain`: The domain name, e.g. example.com.
- `--email`: Your email address to register with Let's Encrypt.
- `--cf-api-token`: A Cloudflare API Token with `Zone:DNS:Edit` permissions.
- `--cert-dir`: Target directory for local certificates (Default: `/etc/lecf/certs`)
- `--renew-days`: Number of days prior to expiration to trigger renewal (Default: `30`)
- `--propagation-seconds`: DNS propagation wait time in seconds (Default: `30`)

## Installation

### Standard Installation

Clone the repository and install the complete directory tree:

```bash
git clone https://github.com/noamanahmed/letsencrypt-cloudflare-homelab.git
cd letsencrypt-cloudflare-homelab

# Ensure scripts are executable
chmod +x bin/lecf lib/*.sh install.sh

# Install system-wide (installs bin/lecf to /usr/local/bin, lib to /usr/local/lib/lecf, hooks to /etc/lecf/hooks)
sudo ./install.sh
```

Alternatively, you can keep the repository directory intact (e.g. in `/opt/letsencrypt-cloudflare-homelab`) and symlink `bin/lecf` to `/usr/local/bin/lecf`:
```bash
sudo ln -s /opt/letsencrypt-cloudflare-homelab/bin/lecf /usr/local/bin/lecf
```

> **Important:** Always install or preserve the complete directory tree (`bin/`, `lib/`, `hooks/`). Do not copy only `bin/lecf` in isolation, as it requires its sibling libraries. Always execute `lecf` directly (e.g., `lecf` or `./bin/lecf`), **never** run `sh lecf` because Alpine's default `/bin/sh` (BusyBox ash) does not support Bash features (`[[ ... ]]`, arrays, `BASH_SOURCE`, and `pipefail`).

### Dependencies

#### Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y bash certbot python3-certbot-dns-cloudflare openssl curl dnsutils
```

#### Alpine Linux

Install Bash and the required Alpine packages:

```sh
apk add --no-cache bash certbot certbot-dns-cloudflare openssl curl bind-tools
```

- **Date Parsing:** Expiry checks use `openssl x509 -checkend`, so GNU `coreutils` is not required.
- **Web Server Deployment:** When running on an Alpine host with OpenRC, `lecf` automatically reloads services using:
  ```sh
  rc-service nginx reload
  rc-service apache2 reload
  ```
  Pre-reload configuration testing (`nginx -t` or `apachectl configtest`) is preserved.

### Automation & Scheduling

#### Alpine Linux (BusyBox crond)

To renew twice daily with BusyBox cron on Alpine, add an entry to `/etc/crontabs/root` (see `cron/crontab.example`):

```cron
0 */12 * * * /usr/local/bin/lecf run nginx --domain example.com --email admin@example.com --cf-api-token xxx
```

Then enable and start `crond`:

```sh
rc-update add crond default
rc-service crond start
```

Alternatively, copy `cron/periodic-daily.example` to `/etc/periodic/daily/lecf` and run `chmod +x /etc/periodic/daily/lecf`.

#### Systemd (Debian / Ubuntu / RHEL)

Enable and start the systemd timer:

```bash
sudo cp systemd/lecf.service /etc/systemd/system/
sudo cp systemd/lecf.timer /etc/systemd/system/
# Edit /etc/systemd/system/lecf.service with your domain, email, and API token
sudo systemctl daemon-reload
sudo systemctl enable --now lecf.timer
```

### Docker & Container Deployment

The container image is built on Alpine Linux (`docker/Dockerfile`). Web servers (Nginx/Apache) do not need to be installed inside the `lecf` container:

1. `lecf` issues and writes certificates to the shared volume (`lecf_certs` and `nginx_ssl`).
2. If `nginx` or `apache` is not installed inside the container, `lecf` deploys the certificates and skips local reload without error.
3. The real web-server container mounts the certificates volume and is reloaded externally (e.g. via `docker exec nginx nginx -s reload` or post-renewal hooks).

Run with Docker Compose:

```bash
cd docker
docker compose up
```

## Architecture

* **`bin/lecf`**: Main executable script wrapping all components (handles symlinks and module loading).
* **`lib/`**: Contains validations (`validate.sh`), certificate management (`cert.sh`), utility logging (`util.sh`), and server deployments (`webserver_nginx.sh`, `webserver_apache.sh`).
* **`hooks/post-renew.d/`**: Post-renewal hook scripts for custom notifications or external container reloads.
* **`cron/`**: Example crontabs for BusyBox `crond` and Alpine periodic tasks.
* **`systemd/`**: Systemd unit and timer definitions.
* **`k8s/`**: Kubernetes `CronJob` definition utilizing secrets and persistent volumes.

## Contributing

Pull requests and issues are welcome.
