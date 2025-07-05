# StreamSource DigitalOcean Deployment Guide

This guide provides step-by-step instructions for deploying StreamSource to a DigitalOcean Droplet with cost optimization for 8-hour daily usage.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Droplet Setup](#initial-droplet-setup)
4. [Application Deployment](#application-deployment)
5. [SSL Certificate Setup](#ssl-certificate-setup)
6. [GitHub Actions Setup](#github-actions-setup)
7. [Cost Optimization](#cost-optimization)
8. [Maintenance](#maintenance)
9. [Troubleshooting](#troubleshooting)

## Overview

### Architecture
- **Single Droplet**: Hosts Rails app, PostgreSQL, Redis, and Nginx
- **Estimated Cost**: ~$6/month (with 16-hour daily shutdown)
- **Recommended Droplet**: Basic ($6/mo) - 1 vCPU, 1GB RAM, 25GB SSD

### Why Droplet over App Platform?
- **Cost Savings**: ~$21/month saved with scheduled shutdowns
- **Flexibility**: Full control over configuration
- **Single Instance**: Perfect for low-traffic internal tools

## Prerequisites

1. DigitalOcean account
2. Domain name (for SSL)
3. GitHub repository with your StreamSource code
4. SSH key pair for secure access

## Initial Droplet Setup

### 1. Create Droplet

```bash
# Via DigitalOcean UI:
# - Choose Ubuntu 22.04 LTS
# - Select Basic plan ($6/month)
# - Choose datacenter closest to users
# - Add your SSH key
# - Enable backups (optional, +$1.20/month)
```

### 2. Initial Server Configuration

SSH into your droplet as root:

```bash
ssh root@your-droplet-ip
```

Run the setup script:

```bash
# Download and run setup script
wget https://raw.githubusercontent.com/YOUR_USERNAME/streamsource/main/deploy/setup-droplet.sh
chmod +x setup-droplet.sh
./setup-droplet.sh
```

### 3. Configure Deploy User

```bash
# Set password for deploy user
passwd deploy

# Add your SSH key to deploy user
su - deploy
mkdir ~/.ssh
chmod 700 ~/.ssh
# Paste your public key into:
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

### 4. Update PostgreSQL Password

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Update password (replace with strong password)
ALTER USER streamsource WITH PASSWORD 'your-strong-password-here';
\q
```

## Application Deployment

### 1. Prepare Shared Files

SSH as deploy user:

```bash
ssh deploy@your-droplet-ip
```

Create environment file:

```bash
cd /var/www/streamsource/shared
cp /path/to/deploy/.env.production.template .env.production
nano .env.production
# Update all values, especially:
# - SECRET_KEY_BASE (generate with: openssl rand -hex 64)
# - DATABASE_URL with your PostgreSQL password
# - APPLICATION_HOST with your domain
```

Create Rails master key:

```bash
# Copy from your local development environment
nano /var/www/streamsource/shared/config/master.key
```

### 2. Configure Nginx

```bash
# Copy nginx configuration
sudo cp /path/to/deploy/nginx.conf /etc/nginx/sites-available/streamsource
sudo ln -s /etc/nginx/sites-available/streamsource /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Update server_name in the config
sudo nano /etc/nginx/sites-available/streamsource
# Replace your-domain.com with your actual domain

# Test configuration
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Setup Systemd Service

```bash
# Copy puma service file
sudo cp /path/to/deploy/puma.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable puma
```

### 4. Deploy Application

Make the deploy script executable and run it:

```bash
chmod +x /path/to/deploy/deploy.sh
# Edit the script to set your GitHub repository URL
nano /path/to/deploy/deploy.sh

# Run deployment
./deploy.sh
```

## SSL Certificate Setup

### Using Let's Encrypt (Free)

```bash
# Run certbot
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Follow prompts to:
# - Enter email
# - Agree to terms
# - Choose redirect option (recommended)

# Test auto-renewal
sudo certbot renew --dry-run
```

## GitHub Actions Setup

### Overview

GitHub Actions provides free CI/CD for public repositories (2,000 minutes/month). This setup includes:
- Automated testing on every push
- Deployment to production on main branch
- Scheduled power management to save costs

### 1. Configure Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

```yaml
# Required for deployment
DROPLET_HOST: your-droplet-ip-or-domain
DEPLOY_SSH_KEY: (contents of your deployment SSH private key)

# Required for power management
DO_API_TOKEN: your-digitalocean-api-token
DROPLET_ID: your-droplet-id

# Optional
SLACK_WEBHOOK: your-slack-webhook-url
```

### 2. Generate Deployment SSH Key

On your local machine:

```bash
# Generate a new SSH key pair for GitHub Actions
ssh-keygen -t ed25519 -f ~/.ssh/github_actions_deploy -C "github-actions"

# Copy the public key to your droplet
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub deploy@your-droplet-ip

# Copy the private key content for GitHub secret
cat ~/.ssh/github_actions_deploy
# Copy this entire output to DEPLOY_SSH_KEY secret
```

### 3. Get DigitalOcean API Token

1. Go to DigitalOcean → API → Tokens
2. Generate new token with read/write access
3. Copy token to DO_API_TOKEN secret

### 4. Find Your Droplet ID

```bash
# Use this command with your API token
curl -X GET \
  -H "Authorization: Bearer YOUR_DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/droplets" \
  | jq '.droplets[] | {id, name}'
```

### 5. Update Repository Settings

In your repository:

1. Update `deploy/github-deploy.sh` permissions:
   ```bash
   chmod +x deploy/github-deploy.sh
   git add deploy/github-deploy.sh
   git commit -m "Make deploy script executable"
   ```

2. Ensure the deploy user can restart services:
   ```bash
   # On your droplet, add to sudoers
   sudo visudo
   # Add this line:
   deploy ALL=(ALL) NOPASSWD: /bin/systemctl restart puma, /bin/systemctl reload nginx
   ```

### 6. Deployment Workflow

The deployment workflow (`.github/workflows/deploy.yml`) runs on:
- Every push to main branch
- Manual trigger via GitHub UI

Workflow steps:
1. Run full test suite
2. Security checks (Brakeman, bundler-audit)
3. Deploy to production if tests pass
4. Health check verification
5. Optional Slack notification

### 7. Power Management Workflow

The power management workflow (`.github/workflows/scheduled-power.yml`) runs:
- **Power ON**: 9 AM EST Monday-Friday
- **Power OFF**: 6 PM EST Monday-Friday
- Manual trigger with action choice

To adjust schedule:
1. Edit the cron expressions in the workflow
2. Times are in UTC (EST+5)

### 8. Manual Deployment

To trigger deployment manually:
1. Go to Actions tab in GitHub
2. Select "Deploy to DigitalOcean"
3. Click "Run workflow"
4. Select branch and run

### 9. Monitoring Deployments

- **GitHub Actions**: Check Actions tab for logs
- **Server logs**: `ssh deploy@your-droplet "tail -f /var/www/streamsource/shared/log/production.log"`
- **Deployment history**: `ssh deploy@your-droplet "ls -la /var/www/streamsource/releases/"`

### Using Let's Encrypt (Free)

```bash
# Run certbot
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Follow prompts to:
# - Enter email
# - Agree to terms
# - Choose redirect option (recommended)

# Test auto-renewal
sudo certbot renew --dry-run
```

## Cost Optimization

### Automated Shutdown/Startup

1. **Setup Shutdown Schedule**:

```bash
sudo chmod +x /path/to/deploy/schedule-power.sh
sudo /path/to/deploy/schedule-power.sh

# Adjust shutdown time (default 6 PM)
crontab -e
# Change: 0 18 * * * to your preferred time
```

2. **Setup Automated Startup** (choose one):

   **Option A: DigitalOcean API** (Recommended)
   ```bash
   # From your local machine or another server
   # Edit do-power-on.sh with your API token and droplet ID
   chmod +x do-power-on.sh
   
   # Add to cron (10 AM startup)
   crontab -e
   0 10 * * 1-5 /path/to/do-power-on.sh
   ```

   **Option B: Manual Startup**
   - Log into DigitalOcean console each morning
   - Click "Power On" for your droplet

### Backup Strategy

1. **Setup Automated Backups**:

```bash
# Copy backup script
sudo cp /path/to/deploy/backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup.sh

# Configure database password
sudo nano /usr/local/bin/backup.sh
# Add: DB_PASSWORD="your-postgres-password"

# Add to cron (daily at 5 AM)
sudo crontab -e
0 5 * * * /usr/local/bin/backup.sh
```

2. **Optional: DigitalOcean Spaces** for offsite backup:
   - Create a Space in DigitalOcean
   - Install s3cmd: `sudo apt-get install s3cmd`
   - Configure s3cmd with your Space credentials
   - Uncomment the upload section in backup.sh

## Maintenance

### Regular Updates

```bash
# System updates (monthly)
sudo apt-get update && sudo apt-get upgrade

# Application updates
cd /path/to/deploy
./deploy.sh
```

### Monitoring

1. **Check Application Health**:
```bash
curl https://your-domain.com/health
```

2. **View Logs**:
```bash
# Application logs
tail -f /var/www/streamsource/shared/log/production.log

# Puma logs
sudo journalctl -u puma -f

# Nginx logs
tail -f /var/www/streamsource/shared/log/nginx.access.log
```

3. **System Resources**:
```bash
htop  # Real-time resource usage
df -h  # Disk usage
```

### Database Maintenance

```bash
# Connect to production database
cd /var/www/streamsource/current
RAILS_ENV=production bundle exec rails console

# Run PostgreSQL vacuum (monthly)
sudo -u postgres psql streamsource_production -c "VACUUM ANALYZE;"
```

## Troubleshooting

### Common Issues

1. **502 Bad Gateway**
   - Check if Puma is running: `sudo systemctl status puma`
   - Check Puma logs: `sudo journalctl -u puma -n 50`
   - Restart: `sudo systemctl restart puma`

2. **Asset Compilation Errors**
   - Check Node/Yarn installation
   - Manually compile: `cd /var/www/streamsource/current && RAILS_ENV=production bundle exec rails assets:precompile`

3. **Database Connection Errors**
   - Verify PostgreSQL is running: `sudo systemctl status postgresql`
   - Check credentials in .env.production
   - Test connection: `RAILS_ENV=production bundle exec rails db:version`

4. **ActionCable/WebSocket Issues**
   - Check Redis: `redis-cli ping`
   - Verify Nginx WebSocket configuration
   - Check browser console for connection errors

### Rollback Deployment

```bash
# List releases
ls -la /var/www/streamsource/releases/

# Rollback to previous release
ln -nfs /var/www/streamsource/releases/[PREVIOUS_TIMESTAMP] /var/www/streamsource/current
sudo systemctl restart puma
```

### Emergency Access

If locked out:
1. Use DigitalOcean console access
2. Boot into recovery mode
3. Reset passwords/SSH keys as needed

## Security Checklist

- [ ] Strong passwords for all accounts
- [ ] SSH key authentication only (disable password auth)
- [ ] Firewall configured (ufw)
- [ ] Fail2ban active
- [ ] SSL certificate installed
- [ ] Regular security updates
- [ ] Database backups configured
- [ ] Application secrets properly managed

## Performance Optimization

For better performance with limited resources:

1. **Tune PostgreSQL** (1GB RAM config):
```bash
sudo nano /etc/postgresql/*/main/postgresql.conf
# Set:
# shared_buffers = 256MB
# effective_cache_size = 768MB
# work_mem = 4MB
sudo systemctl restart postgresql
```

2. **Optimize Puma Workers**:
   - With 1GB RAM, use 2 workers max
   - Adjust in .env.production: `WEB_CONCURRENCY=2`

3. **Enable Swap** (if needed):
```bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Support

For StreamSource-specific issues:
- Check logs first
- Review this guide
- Consult Rails and DigitalOcean documentation

Remember to update this guide as your deployment evolves!