# Let's Encrypt + Cloudflare Toolkit (Homelab)

**Repository:** [https://github.com/noamanahmed/letsencrypt-cloudflare-homelab](https://github.com/noamanahmed/letsencrypt-cloudflare-homelab)

A lightweight shell-based toolkit for automating Let's Encrypt SSL certificate issuance and renewal using Cloudflare DNS-01 validation—designed for homelabs, private networks, and systems without public IPv4, with built-in support for `nginx`, `apache`, `systemd` timers, and `Docker`.

## Features

- **No Public IPv4 needed:** Uses DNS-01 challenge via Cloudflare to validate identity.
- **Dependency Minimal:** Pure Bash, relies on standard UNIX tools + `certbot` with cloudflare plugin.
- **Idempotent:** Safe to run interactively, as a systemd service, cron, or Kubernetes job without interfering with live certificates unnecessarily.
- **Multiple Integrations:**
  - `Docker` + `docker-compose`
  - `Kubernetes` CronJobs (`k8s/cronjob.yaml`)
  - `Systemd` Timers

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

## Installation

```bash
git clone https://github.com/noamanahmed/letsencrypt-cloudflare-homelab.git
cd letsencrypt-cloudflare-homelab

# Ensure scripts are executable
chmod +x bin/lecf lib/*.sh
```

Ensure the following dependencies are installed:
* `curl`, `awk`, `sed`, `grep`, `openssl`, `dig`
* `certbot` along with `python3-certbot-dns-cloudflare` (or `certbot-dns-cloudflare` on Alpine).

## Architecture

* **`bin/lecf`**: Main executable script wrapping all components.
* **`lib/`**: Contains validations, CLI argument parsing, API calling, and webserver-specific (nginx/apache) deployments.
* **`k8s/`**: Contains an out-of-the-box Kubernetes `CronJob` definition utilizing secrets and persistent volume claims for cluster-wide SSL issuance.

## Contributing

Pull requests and issues are welcome.
