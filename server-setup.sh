#!/bin/bash
# ---------------------------------------------------------------------------
# TechTriage - EC2 "User data" script (Amazon Linux 2023)
#
# Paste this whole file into the "User data" box when launching each EC2
# instance. Change APP_ENV for each server. It runs once, as root, on the
# first boot.
#
# What it does:
#   1. Installs Docker and the Docker Compose plugin
#   2. Downloads compose.yaml from the public GitHub repo
#   3. Writes this server's settings to /opt/techtriage/.env
#   4. Pulls the public image from GHCR and starts it
#
# Log file on the server: /var/log/techtriage-setup.log
# No passwords or keys are needed: the repo and the GHCR image are public.
# ---------------------------------------------------------------------------

# ===== CHANGE THESE =========================================================
APP_ENV="development"        # development | testing | staging | production
GITHUB_OWNER="MurtazaRahimy" # GitHub user that owns the techtriage repo
IMAGE_TAG="latest"           # "latest" = newest build of main
# ============================================================================

REPO="techtriage"
BRANCH="main"
COMPOSE_VERSION="v2.29.7"
APP_DIR="/opt/techtriage"

set -euo pipefail
exec > >(tee -a /var/log/techtriage-setup.log) 2>&1
echo "=== TechTriage setup started $(date -u +%FT%TZ) for env=${APP_ENV} ==="

# GHCR image names must be lowercase.
OWNER_LC=$(echo "$GITHUB_OWNER" | tr '[:upper:]' '[:lower:]')
IMAGE="ghcr.io/${OWNER_LC}/${REPO}"

# 1. Docker engine (from the Amazon Linux 2023 repos)
dnf install -y docker
systemctl enable --now docker

# 1b. Docker Compose v2 plugin (not in the AL2023 repos, so download it)
ARCH=$(uname -m)   # x86_64 on t3.micro
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL --retry 5 \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker --version
docker compose version

# 2. App folder and compose.yaml from the repo
mkdir -p "$APP_DIR"
cd "$APP_DIR"
curl -fsSL --retry 5 \
  "https://raw.githubusercontent.com/${GITHUB_OWNER}/${REPO}/${BRANCH}/compose.yaml" \
  -o compose.yaml

# 3. This server's settings (kept on the server, never committed to Git)
cat > .env <<EOF
APP_ENV=${APP_ENV}
IMAGE=${IMAGE}
IMAGE_TAG=${IMAGE_TAG}
EOF
chmod 600 .env

# 4. Pull the public image from GHCR and start it
docker compose pull
docker compose up -d

# Quick self-check
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1/health >/dev/null; then
    echo "Health check OK"
    curl -fsS http://127.0.0.1/version; echo
    break
  fi
  sleep 2
done
docker compose ps

echo "=== TechTriage setup finished $(date -u +%FT%TZ) ==="
