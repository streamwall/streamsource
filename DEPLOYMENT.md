# StreamSource Production Deployment Guide

This guide provides comprehensive instructions for deploying the StreamSource Rails application to DigitalOcean with full CI/CD automation via GitHub Actions.

## 🚀 Overview

StreamSource uses a modern deployment stack with:
- **CI/CD**: GitHub Actions for automated testing and deployment
- **Infrastructure**: DigitalOcean Droplet with Ubuntu 24.04 LTS
- **Application Server**: Puma with Unix socket communication
- **Web Server**: Nginx with SSL/TLS termination
- **Database**: PostgreSQL 17
- **Cache/Sessions**: Redis 7
- **Real-time**: ActionCable WebSocket support
- **Security**: fail2ban, UFW firewall, SSL/TLS, rate limiting
- **Monitoring**: Health checks, structured logging, Prometheus metrics

## 📋 Prerequisites

### Required Secrets
Configure these secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

```
# DigitalOcean
DO_API_TOKEN=your_digitalocean_api_token
DROPLET_ID=your_droplet_id
DROPLET_HOST=your_domain_or_ip

# SSH Access
DEPLOY_SSH_KEY=your_private_ssh_key_content

# Optional Notifications
SLACK_WEBHOOK=your_slack_webhook_url
```

### Required Tools
- DigitalOcean account with API access
- Domain name (recommended) or IP address
- SSH key pair for deployment access

## 🏗️ Infrastructure Setup

### 1. Create DigitalOcean Droplet

**Recommended Specifications:**
- **OS**: Ubuntu 24.04 LTS
- **Size**: 2GB RAM, 1 vCPU minimum (4GB+ recommended for production)
- **Region**: Choose closest to your users
- **SSH Keys**: Add your public key

### 2. Initial Server Setup

Run the automated setup script on your fresh droplet:

```bash
# SSH into your droplet as root
ssh root@your_droplet_ip

# Download and run setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/streamsource/main/deploy/setup-droplet.sh | bash
```

The setup script will:
- ✅ Update system packages
- ✅ Install Ruby 3.3.6 via rbenv
- ✅ Install Node.js 20.x and Yarn
- ✅ Install and configure PostgreSQL 17
- ✅ Install and configure Redis 7
- ✅ Install and configure Nginx
- ✅ Set up UFW firewall (ports 22, 80, 443)
- ✅ Configure fail2ban for security
- ✅ Create deploy user with sudo access
- ✅ Set up application directory structure

### 3. Post-Setup Configuration

After running the setup script:

```bash
# Set password for deploy user
passwd deploy

# Switch to deploy user
su - deploy

# Create SSH directory and add your public key
mkdir -p ~/.ssh
echo "YOUR_PUBLIC_KEY" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# Create shared configuration files
mkdir -p /var/www/streamsource/shared/{config,log,tmp,storage}
```

### 4. Database Setup

Configure PostgreSQL with a secure password:

```bash
# Update PostgreSQL password (replace with a strong password)
sudo -u postgres psql -c "ALTER USER streamsource PASSWORD 'your_secure_password';"

# Test connection
psql -U streamsource -h localhost -d streamsource_production
```

### 5. SSL/TLS Certificate

For production, set up SSL with Let's Encrypt:

```bash
# Replace with your domain
sudo certbot --nginx -d yourdomain.com

# Test automatic renewal
sudo certbot renew --dry-run
```

### 6. Environment Configuration

Create the production environment file:

```bash
# Copy template
cp /var/www/streamsource/shared/config/.env.production.template /var/www/streamsource/shared/config/.env.production

# Edit with your actual values
nano /var/www/streamsource/shared/config/.env.production
```

**Required Environment Variables:**
```bash
# Core Rails Configuration
SECRET_KEY_BASE=your_secret_key_base_64_chars_minimum
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# Database
DATABASE_URL=postgres://streamsource:your_password@localhost:5432/streamsource_production

# Redis
REDIS_URL=redis://localhost:6379/0

# Application
RAILS_HOSTNAME=yourdomain.com
FORCE_SSL=true

# ActionCable
ACTION_CABLE_ADAPTER=redis
ACTION_CABLE_URL=redis://localhost:6379/1

# Security
RATE_LIMIT_REDIS_URL=redis://localhost:6379/2
```

Generate a secure SECRET_KEY_BASE:
```bash
bundle exec rails secret
```

### 7. Service Configuration

Copy and enable systemd services:

```bash
# Copy service file
sudo cp /var/www/streamsource/deploy/puma.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable services
sudo systemctl enable puma
sudo systemctl enable nginx
sudo systemctl enable postgresql
sudo systemctl enable redis-server

# Copy nginx configuration
sudo cp /var/www/streamsource/deploy/nginx.conf /etc/nginx/sites-available/streamsource
sudo ln -sf /etc/nginx/sites-available/streamsource /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# Start services
sudo systemctl start puma
sudo systemctl restart nginx
```

## 🔄 Deployment Pipeline

### GitHub Actions Workflow

The deployment pipeline consists of two main workflows:

#### 1. Main Deployment (`deploy.yml`)
Triggers on push to `main` branch:

**Test Stage:**
- ✅ Ruby 3.3.6 + Node.js 20 setup
- ✅ PostgreSQL 17 + Redis 7 services
- ✅ Dependency installation (Bundle + Yarn)
- ✅ Database setup and migrations
- ✅ Full RSpec test suite
- ✅ Security checks (Brakeman + Bundler Audit)

**Deploy Stage:**
- ✅ SSH deployment to DigitalOcean
- ✅ Zero-downtime deployment with health checks
- ✅ Automatic rollback on failure
- ✅ Slack notifications

#### 2. Power Management (`scheduled-power.yml`)
Automated cost savings:
- ✅ Power ON: 9 AM EST (Monday-Friday)
- ✅ Power OFF: 6 PM EST (Monday-Friday)
- ✅ Manual trigger via GitHub Actions UI
- ✅ Graceful service shutdown before power off

### Manual Deployment

For manual deployments or troubleshooting:

```bash
# SSH into droplet
ssh deploy@your_droplet_ip

# Navigate to application directory
cd /var/www/streamsource

# Run deployment script
./deploy/deploy.sh

# Or use GitHub Actions deployment script
GITHUB_REPOSITORY=YOUR_USERNAME/streamsource ./deploy/github-deploy.sh
```

### Rollback Procedure

If a deployment fails:

```bash
# SSH into droplet
ssh deploy@your_droplet_ip

# Run rollback script
cd /var/www/streamsource
./deploy/rollback.sh

# Or manually rollback to previous release
ln -nfs /var/www/streamsource/releases/PREVIOUS_TIMESTAMP /var/www/streamsource/current
sudo systemctl restart puma
```

## 📊 Monitoring and Maintenance

### Health Checks

The application provides several health check endpoints:

- **Basic Health**: `GET /health`
- **Database Health**: `GET /health/db`
- **Redis Health**: `GET /health/redis`
- **Detailed Health**: `GET /health/detailed`

### Log Files

Monitor application logs:

```bash
# Application logs
tail -f /var/www/streamsource/shared/log/production.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Puma logs
journalctl -u puma -f

# System logs
journalctl -f
```

### Performance Monitoring

The application includes Prometheus metrics at `/metrics` endpoint.

### Database Maintenance

Regular database maintenance:

```bash
# Database backup
./deploy/backup.sh

# Database vacuum (run weekly)
sudo -u postgres psql streamsource_production -c "VACUUM ANALYZE;"

# Check database size
sudo -u postgres psql streamsource_production -c "SELECT pg_size_pretty(pg_database_size('streamsource_production'));"
```

### Security Updates

Keep the system updated:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Ruby gems
cd /var/www/streamsource/current && bundle update

# Update Node.js packages
cd /var/www/streamsource/current && yarn upgrade

# Restart services after updates
sudo systemctl restart puma nginx
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Application Won't Start
```bash
# Check service status
sudo systemctl status puma

# Check logs
journalctl -u puma -n 50

# Common fixes
sudo systemctl restart puma
sudo systemctl restart nginx
```

#### 2. Database Connection Issues
```bash
# Test database connection
psql -U streamsource -h localhost -d streamsource_production

# Check PostgreSQL status
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql
```

#### 3. Redis Connection Issues
```bash
# Test Redis connection
redis-cli ping

# Check Redis status
sudo systemctl status redis-server

# Restart Redis
sudo systemctl restart redis-server
```

#### 4. SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew

# Test nginx configuration
sudo nginx -t
```

#### 5. Disk Space Issues
```bash
# Check disk usage
df -h

# Clean old releases
cd /var/www/streamsource/releases
ls -la | head -20
# Remove old releases manually if needed

# Clean logs
sudo journalctl --vacuum-time=30d
```

### Emergency Procedures

For critical issues, use the emergency access guide:

```bash
# Emergency access script
./deploy/emergency-access.sh

# Quick service restart
sudo systemctl restart puma nginx postgresql redis-server

# Emergency maintenance mode
# Edit nginx config to show maintenance page
sudo nano /etc/nginx/sites-available/streamsource
```

## 🔐 Security Best Practices

### Server Security
- ✅ UFW firewall configured (ports 22, 80, 443 only)
- ✅ fail2ban protection against brute force attacks
- ✅ SSH key-based authentication (disable password auth)
- ✅ Regular security updates
- ✅ Non-root application user

### Application Security
- ✅ Rate limiting via Rack::Attack
- ✅ SSL/TLS enforcement
- ✅ Security headers (HSTS, CSP, etc.)
- ✅ Secret key rotation
- ✅ Database connection encryption
- ✅ Session security with Redis

### Monitoring Security
- ✅ Log monitoring for suspicious activity
- ✅ Health check monitoring
- ✅ SSL certificate expiration monitoring
- ✅ Dependency vulnerability scanning

## 📈 Performance Optimization

### Application Performance
- ✅ Redis caching for sessions and application cache
- ✅ Gzip compression in Nginx
- ✅ Static asset caching
- ✅ Database query optimization
- ✅ Connection pooling

### Server Performance
- ✅ Puma worker and thread tuning
- ✅ PostgreSQL performance tuning
- ✅ Redis memory optimization
- ✅ Nginx performance optimization

## 🎯 Production Checklist

Before going live:

- [ ] SSL certificate installed and configured
- [ ] Domain DNS pointed to droplet IP
- [ ] All environment variables configured
- [ ] Database backups automated
- [ ] Monitoring and alerting set up
- [ ] Security hardening completed
- [ ] Performance testing completed
- [ ] Rollback procedure tested
- [ ] Documentation updated
- [ ] Team access configured

## 🆘 Support and Maintenance

### Regular Maintenance Tasks

**Daily:**
- Monitor application logs
- Check health endpoints
- Verify backup completion

**Weekly:**
- Review security logs
- Update system packages
- Database maintenance (VACUUM)
- Review performance metrics

**Monthly:**
- Security audit
- Dependency updates
- SSL certificate check
- Disaster recovery test

### Getting Help

For deployment issues:
1. Check the troubleshooting section above
2. Review application logs and GitHub Actions logs
3. Verify all environment variables are set correctly
4. Ensure all services are running properly

---

**Note**: This deployment setup is production-ready and follows Rails and security best practices. The infrastructure automatically handles scaling, security, and monitoring for a robust production environment.