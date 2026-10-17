# TechTriage

Student technical troubleshooting assistant, deployed through a four-environment DevOps pipeline.
SWE40006 Software Deployment and Evolution, Group 05 (CL03 Wed 16:30).

**Current stage: Level 1 (pipeline infrastructure).** Each server runs a placeholder page showing its environment name and commit ID. The real Flask app arrives in Level 3.

## Team

| Member | Lead role |
|---|---|
| Saffan Malik | Pipeline |
| Tyler Marwood | Cloud and Security |
| Murtaza Rahimy | Application |
| Sy Dam Viet Nguyen | Testing |

## Agreed names

| Item | Value |
|---|---|
| Repository | [`MurtazaRahimy/techtriage`](https://github.com/MurtazaRahimy/techtriage) (public) |
| Environments | `development`, `testing`, `staging`, `production` |
| AWS account | AWS Academy Learner Lab |
| AWS region | `us-east-1` (Learner Lab only allows us-east-1 / us-west-2) |
| Server role | `LabInstanceProfile` (ready-made in Learner Lab, includes Systems Manager access) |
| Container image | `ghcr.io/murtazarahimy/techtriage` (public) |
| EC2 names | `techtriage-<env>` (tag `Environment=<env>`) |
| Security group | `techtriage-web` |

## Pipeline

```
GitHub repo  ->  GitHub Actions (build + smoke test)  ->  GHCR image  ->  4 x EC2 (Docker Compose)
```

| Tool | Job |
|---|---|
| GitHub | Stores code, reviews pull requests |
| GitHub Actions | Builds the image, tags it with the commit SHA, pushes to GHCR |
| GHCR | Stores the public Docker image |
| AWS EC2 (Amazon Linux 2023, t3.micro) | One server per environment |
| Docker Compose | Runs the containers on each server |
| AWS Systems Manager | Remote access and commands. No SSH, port 22 closed |

## Servers

| Environment | Instance ID | Public address | Notes |
|---|---|---|---|
| development | `i-...` | `http://...` | Stop when not in use |
| testing | `i-...` | `http://...` | Stop when not in use |
| staging | `i-...` | `http://...` | Stop when not in use |
| production | `i-...` | `http://...` | Elastic IP (fixed) |

Each server exposes:

- `/` placeholder page (environment and commit)
- `/version` the same as JSON
- `/health` returns `ok`

## How to log in to a server (Session Manager)

There is no SSH key and port 22 is closed.

1. AWS Console → **Systems Manager** → **Session Manager** → **Start session**
2. Pick `techtriage-<env>` → **Start session**
3. Useful commands:

```bash
cd /opt/techtriage
sudo docker compose ps
sudo docker compose logs --tail 50
curl -s localhost/version
sudo cat /var/log/techtriage-setup.log
```

## Branch rules

- `main` = released code. `develop` = integrated work.
- New work goes on a `feature/<short-name>` branch → pull request into `develop` → when a release is ready, pull request `develop` → `main`.
- `main` and `develop` are protected. No direct pushes, no force-pushes, each pull request needs **1 approval** and a passing **build** check.
- Never commit passwords, AWS keys or `.env` files. The repo is public, and secret scanning and push protection are on.

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Level 1 placeholder image (nginx) |
| `placeholder/` | Page script and nginx config for the placeholder |
| `compose.yaml` | Services run on each server |
| `server-setup.sh` | EC2 user data: installs Docker and Compose, starts the stack |
| `.github/workflows/ci.yml` | Build, smoke test, push to GHCR |
| `.env.example` | Settings each server keeps in `/opt/techtriage/.env` |

## What Level 3 replaces

- `Dockerfile` → Flask + Gunicorn app image (the `placeholder/` folder is deleted)
- `compose.yaml` → add a `db` service (PostgreSQL, named volume, port 5432 **not** published) and database settings in each server's `.env`
- `ci.yml` → add lint, pytest and coverage jobs (Level 3), then SSM deploy jobs (Level 4)
