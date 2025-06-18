# CI/CD Documentation

This document describes the CI/CD pipeline for StreamSource, supporting both DigitalOcean App Platform and Droplet deployments.

## Overview

The CI/CD pipeline supports:
- Automated testing on all branches
- Deployment to staging and production
- Both App Platform (PaaS) and Droplets (IaaS) deployments
- Rollback capabilities
- Health checks and monitoring

## GitHub Actions Workflows

### Main CI/CD Workflow (`.github/workflows/ci-cd.yml`)

Runs on:
- Push to `main` or `develop` branches
- Pull requests to `main`

Jobs:
1. **Test**: Runs RSpec tests, security checks, and linters
2. **Deploy**: Deploys to production (main branch only)
3. **Terraform**: Plans infrastructure changes

### Improved CI/CD Workflow (`.github/workflows/ci-cd-improved.yml`)

Enhanced version with:
- Docker image building
- Staging environment support
- Manual deployment triggers
- Parallel deployment strategies
- Cleanup and notifications

## Deployment Strategies

### 1. App Platform Deployment

**Pros:**
- Managed platform, less maintenance
- Automatic SSL certificates
- Built-in scaling and monitoring
- GitHub integration

**Process:**
1. Push to main branch
2. GitHub Actions builds and tests
3. Updates App Platform spec
4. App Platform builds and deploys
5. Runs database migrations
6. Health check verification

### 2. Droplet Deployment with Ansible

**Pros:**
- Full control over infrastructure
- Cost-effective for larger deployments
- Custom configurations possible
- Blue-green deployment support

**Process:**
1. Push to main branch
2. GitHub Actions builds and tests
3. Builds Docker image (optional)
4. Runs Ansible playbook
5. Rolling deployment across servers
6. Health check verification

## Environment Configuration

### Required GitHub Secrets

**For All Deployments:**
- `DIGITALOCEAN_ACCESS_TOKEN`: DO API token
- `RAILS_MASTER_KEY`: Rails encryption key
- `SECRET_KEY_BASE`: Rails secret key
- `JWT_SECRET`: JWT authentication secret
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string

**For App Platform:**
- `DO_APP_ID`: Production app ID
- `DO_STAGING_APP_ID`: Staging app ID (optional)

**For Droplets:**
- `DROPLET_SSH_KEY`: SSH private key for Ansible
- `SSH_KEY_FINGERPRINTS`: DO SSH key fingerprints

**For Terraform State (optional):**
- `DO_SPACES_BUCKET`: Spaces bucket for state
- `DO_SPACES_ACCESS_KEY`: Spaces access key
- `DO_SPACES_SECRET_KEY`: Spaces secret key

### Environment Variables

Set in GitHub repository settings:
- `USE_DROPLETS`: Set to "true" for droplet deployment
- `APP_DOMAIN`: Production domain name

## Manual Deployment

### Using the Deploy Script

```bash
# Deploy to production using auto-detected method
./scripts/deploy.sh

# Deploy to staging using App Platform
./scripts/deploy.sh staging app-platform

# Deploy to production using Droplets
./scripts/deploy.sh production droplets

# Skip tests (not recommended)
SKIP_TESTS=true ./scripts/deploy.sh production
```

### Using GitHub Actions Manually

1. Go to Actions tab in GitHub
2. Select "CI/CD Pipeline" workflow
3. Click "Run workflow"
4. Select environment and deployment type

## Rollback Procedures

### App Platform Rollback

```bash
# List recent deployments
doctl apps list-deployments $DO_APP_ID

# Create new deployment from previous version
doctl apps create-deployment $DO_APP_ID --force-rebuild
```

### Droplet Rollback

```bash
# Using Ansible
cd ansible
ansible-playbook rollback.yml -i inventory/production.yml

# Manual rollback
ssh rails@server-ip
cd /home/rails/streamsource
ln -sfn releases/20240115120000 current
sudo systemctl restart puma
```

## Monitoring Deployments

### Health Checks

All deployments include health checks:
- Endpoint: `/health`
- Checks: Database connectivity, Redis connectivity
- Timeout: 60 seconds post-deployment

### Logs

**App Platform:**
```bash
doctl apps logs $DO_APP_ID --tail -f
```

**Droplets:**
```bash
# Application logs
ssh rails@server-ip "tail -f /home/rails/streamsource/log/production.log"

# System logs
ssh rails@server-ip "sudo journalctl -u puma -f"
```

## Troubleshooting

### Common Issues

1. **Deployment fails with "unhealthy" status**
   - Check application logs for errors
   - Verify environment variables are set
   - Ensure database migrations completed

2. **Assets not loading**
   - Verify asset compilation succeeded
   - Check Nginx configuration (droplets)
   - Ensure RAILS_SERVE_STATIC_FILES is set

3. **Database connection errors**
   - Verify DATABASE_URL is correct
   - Check database firewall rules
   - Ensure migrations have run

### Debug Commands

```bash
# Check deployment status
doctl apps get $DO_APP_ID

# SSH to droplet
ssh -v rails@droplet-ip

# Test database connection
doctl apps run $DO_APP_ID web -- bundle exec rails db:version

# Run console
doctl apps run $DO_APP_ID web -- bundle exec rails console
```

## Best Practices

1. **Always test locally first**
   ```bash
   docker compose run web bin/test
   ```

2. **Use staging environment**
   - Deploy to staging first
   - Run smoke tests
   - Then deploy to production

3. **Monitor after deployment**
   - Watch logs for 5-10 minutes
   - Check error tracking service
   - Verify key user flows work

4. **Keep secrets secure**
   - Rotate secrets regularly
   - Never commit secrets
   - Use GitHub secrets for sensitive data

5. **Infrastructure as Code**
   - All infrastructure changes through Terraform
   - Review terraform plan before applying
   - Keep terraform state secure

## Deployment Checklist

- [ ] All tests passing
- [ ] Security scan clean
- [ ] Linting passed
- [ ] Database migrations reviewed
- [ ] Environment variables verified
- [ ] Rollback plan ready
- [ ] Monitoring alerts configured
- [ ] Team notified of deployment

## Emergency Procedures

### Complete Outage

1. Check DigitalOcean status page
2. Verify DNS resolution
3. Check load balancer/proxy status
4. SSH to servers and check services
5. Review recent deployments
6. Rollback if necessary

### Performance Issues

1. Check CPU/memory usage
2. Review slow query logs
3. Check Redis memory usage
4. Scale horizontally if needed
5. Enable emergency caching

### Security Incident

1. Disable affected endpoints
2. Rotate all secrets
3. Review access logs
4. Apply security patches
5. Notify security team