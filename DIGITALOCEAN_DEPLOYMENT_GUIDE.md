# StreamSource DigitalOcean Deployment Guide (Docker-First)

This guide provides step-by-step instructions for deploying StreamSource to a DigitalOcean Droplet using Docker.
It is optimized for low-cost, single-droplet production setups and avoids installing Ruby/Node on the host.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Droplet Setup](#initial-droplet-setup)
4. [Docker-First Application Deployment](#docker-first-application-deployment)
5. [SSL/TLS Setup](#ssltls-setup)
6. [GitHub Actions Setup](#github-actions-setup)
7. [Cost Optimization](#cost-optimization)
8. [Maintenance](#maintenance)
9. [Troubleshooting](#troubleshooting)

## Overview

### Architecture
- **Docker-first**: Rails app runs in a container built from the repo Dockerfile
- **Database**: PostgreSQL 18 (managed or containerized)
- **Cache/Sessions**: Redis 8 (managed or containerized)
- **Reverse Proxy**: Nginx/Caddy or a cloud load balancer

### Estimated Cost
- **Droplet**: ~$6/month (Basic, 1 vCPU, 1GB RAM, 25GB SSD)
- **Optional**: Managed DB/Redis adds cost but simplifies ops

## Prerequisites

1. DigitalOcean account
2. Domain name (recommended for SSL)
3. GitHub repository with your StreamSource code
4. SSH key pair for secure access
5. Docker Engine + Docker Compose plugin (installed on the droplet)

## Initial Droplet Setup

### 1. Create Droplet

```bash
# Via DigitalOcean UI:
# - Choose Ubuntu 24.04 LTS
# - Select Basic plan ($6/month)
# - Choose datacenter closest to users
# - Add your SSH key
# - Enable backups (optional)
```

### 2. SSH into the Droplet

```bash
ssh root@your-droplet-ip
```

### 3. Install Docker Engine + Compose

Install Docker using the official Docker docs for your OS. Confirm installation:

```bash
docker --version
docker compose version
```

### 4. Create a Deploy User (Optional but Recommended)

```bash
adduser deploy
usermod -aG sudo deploy
usermod -aG docker deploy
```

Log in as the deploy user:

```bash
su - deploy
```

## Docker-First Application Deployment

### 1. Clone the Repository

```bash
mkdir -p /var/www
cd /var/www
git clone https://github.com/YOUR_USERNAME/streamsource.git
cd streamsource
```

### 2. Configure Environment

Create a production env file from the template:

```bash
cp deploy/.env.production.template .env.production
nano .env.production
```

Update at least:
- `SECRET_KEY_BASE`
- `DATABASE_URL`
- `REDIS_URL`
- `APPLICATION_HOST`

If your env file lives elsewhere, set `STREAMSOURCE_ENV_FILE=/path/to/.env.production` when running Compose.
To deploy a registry image, set `STREAMSOURCE_IMAGE=ghcr.io/your-org/streamsource:tag`.

### 3. Start Services with Docker Compose

Start the app against external PostgreSQL/Redis (recommended for production):

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d web
```

If you want local containers instead, you can start them explicitly:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d web db redis
```

### 4. Verify the App

```bash
curl -f http://localhost:3000/health
```

## SSL/TLS Setup

Terminate TLS at a reverse proxy or a cloud load balancer. Common options:
- **DigitalOcean Load Balancer** (simplest)
- **Nginx** on the droplet
- **Caddy** (automatic HTTPS)

If using Nginx, point it to `http://127.0.0.1:3000` and enable HTTPS with Let's Encrypt.

## GitHub Actions Setup

The `deploy.yml` workflow builds and pushes a Docker image (GHCR) and then SSHes into the droplet to pull and restart
the container with Docker Compose. If the repository is private, run `docker login ghcr.io` on the droplet using a
PAT that has read access to packages.

A minimal deploy step on the droplet looks like this:

```bash
cd /var/www/streamsource
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull web
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d web
```

## Cost Optimization

### Automated Shutdown/Startup

You can still use the scheduled power workflows, but update any shutdown scripts to stop containers first:

```bash
cd /var/www/streamsource
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
sudo shutdown -h now
```

For automated startup, use DigitalOcean's API to power on the droplet, then start containers:

```bash
cd /var/www/streamsource
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d web db redis
```

## Maintenance

### Regular Updates

```bash
# Update system packages (monthly)
sudo apt-get update && sudo apt-get upgrade

# Pull new image (if using a registry)
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull web

# Recreate containers
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d web
```

### Logs

```bash
# App logs
cd /var/www/streamsource
docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f web
```

### Database Maintenance

If you use containerized PostgreSQL:

```bash
# Example: run psql inside the container
cd /var/www/streamsource
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec db psql -U streamsource -d streamsource_production
```

## Troubleshooting

### 1. App Not Responding

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f web
```

### 2. Database Connection Errors

- Confirm `DATABASE_URL` is correct
- Check Postgres container: `docker compose logs db`

### 3. Asset Build Errors

- Rebuild the image: `docker compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache web`

### 4. Rollback

If using a registry, pin to a previous image tag:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d web
```

## Security Checklist

- [ ] SSH key authentication only (disable password auth)
- [ ] Firewall configured (UFW)
- [ ] SSL certificate installed
- [ ] Regular security updates
- [ ] Backups configured

---

This guide assumes a Docker-first deployment. The legacy, host-based deploy scripts in `deploy/` can be used if you
need them, but they are no longer the recommended path.
