# StreamSource Deployment Guide

This guide covers deploying StreamSource to DigitalOcean using either App Platform or Droplets.

## Prerequisites

1. **DigitalOcean Account**: Create an account at [digitalocean.com](https://digitalocean.com)
2. **API Token**: Generate from DigitalOcean control panel
3. **Terraform**: Install version 1.0 or later
4. **Ansible**: Install version 2.9 or later (for Droplet deployment)
5. **SSH Key**: Generate if you don't have one:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/digitalocean_rsa
   ```

## Deployment Options

### Option 1: App Platform (Recommended for simplicity)

App Platform provides a managed environment with automatic scaling and deployments.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

terraform init
terraform plan
terraform apply
```

### Option 2: Droplets + Ansible (Recommended for control)

Droplets with Ansible provide full control over the infrastructure.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set use_droplets = true

# Add SSH key to DigitalOcean
doctl compute ssh-key import ansible-key --public-key-file ~/.ssh/digitalocean_rsa.pub

# Get the fingerprint
doctl compute ssh-key list

# Add fingerprint to terraform.tfvars
# ssh_key_fingerprints = ["your:fingerprint:here"]

terraform init
terraform plan
terraform apply
```

## Configuration Steps

### 1. Generate Secrets

```bash
# Generate Rails secrets
rails secret  # For SECRET_KEY_BASE
rails secret  # For JWT_SECRET

# Get master key
cat config/master.key  # For RAILS_MASTER_KEY
```

### 2. Configure Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
# DigitalOcean API token
do_token = "dop_v1_..."

# Application settings
app_name = "streamsource"
region   = "nyc3"

# For Droplet deployment
use_droplets = true
ssh_key_fingerprints = ["ab:cd:ef:..."]

# GitHub repository
github_repo = "https://github.com/yourusername/streamsource.git"
github_branch = "main"

# Secrets
secret_key_base  = "your-generated-secret"
jwt_secret       = "your-generated-jwt-secret"
rails_master_key = "your-master-key"
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform apply
```

### 4. Verify Deployment

For App Platform:
```bash
doctl apps list
doctl apps logs <app-id>
```

For Droplets:
```bash
# Check Ansible ran successfully
cat terraform/ansible_vars.json

# SSH to server
ssh rails@<droplet-ip>

# Check services
sudo systemctl status puma
sudo systemctl status nginx
```

## Post-Deployment

### 1. Configure DNS

1. Add domain to DigitalOcean:
   ```bash
   doctl compute domain create yourdomain.com
   ```

2. Update nameservers at your registrar to:
   - ns1.digitalocean.com
   - ns2.digitalocean.com
   - ns3.digitalocean.com

3. Update Terraform with domain:
   ```hcl
   app_domain = "yourdomain.com"
   ```

### 2. SSL Certificate

For Droplets, set up Let's Encrypt:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/ssl.yml
```

### 3. Enable Backups

```bash
# For databases (already enabled in Terraform)
doctl databases backups list <database-id>

# For droplets
doctl compute droplet-action backup <droplet-id>
```

## Monitoring

### Health Checks

- App Platform: `https://your-app.ondigitalocean.app/health`
- Droplets: `https://your-domain.com/health`

### Logs

App Platform:
```bash
doctl apps logs <app-id> --tail
```

Droplets:
```bash
ssh rails@<ip> "journalctl -u puma -f"
```

### Metrics

- DigitalOcean Monitoring (built-in)
- Prometheus endpoint: `/metrics`

## Scaling

### App Platform

Edit `terraform.tfvars`:
```hcl
app_instance_count = 3
app_instance_size = "professional-xs"
```

### Droplets

Add more droplets:
```hcl
# In terraform/main.tf, change count
resource "digitalocean_droplet" "app" {
  count = 3  # Was 1
  ...
}
```

## Troubleshooting

### Database Connection Issues

1. Check firewall rules:
   ```bash
   doctl databases firewalls list <database-id>
   ```

2. Test connection:
   ```bash
   psql $DATABASE_URL
   ```

### Application Errors

1. Check logs:
   ```bash
   # App Platform
   doctl apps logs <app-id> --type run
   
   # Droplets
   ssh rails@<ip> "tail -f /home/rails/streamsource/log/production.log"
   ```

2. Run console:
   ```bash
   # Droplets
   ssh rails@<ip>
   cd /home/rails/streamsource
   bundle exec rails console -e production
   ```

### Deployment Failures

1. Check Terraform state:
   ```bash
   terraform show
   ```

2. Re-run Ansible manually:
   ```bash
   cd ansible
   ansible-playbook site.yml -i inventory/hosts.yml
   ```

## Maintenance

### Updates

1. Update code:
   ```bash
   git push origin main
   ```

2. Deploy:
   - App Platform: Automatic
   - Droplets: Run Ansible
     ```bash
     ansible-playbook ansible/site.yml --tags app
     ```

### Database Maintenance

Scheduled for Sundays at 2 AM UTC. To change:
```hcl
maintenance_window {
  day  = "wednesday"
  hour = "03:00"
}
```

### Backup Restore

```bash
# List backups
doctl databases backups list <database-id>

# Restore
doctl databases restore <database-id> --backup-id <backup-id>
```

## Cost Optimization

### Estimated Monthly Costs

- Database: $15 (basic)
- Redis: $15 (basic)
- App Platform: $5-$40 (depending on size)
- Droplets: $6-$48 per instance
- Load Balancer: $12 (if needed)
- Backups: ~$1 per GB

### Tips

1. Use smallest sizes for development
2. Scale horizontally rather than vertically
3. Use DigitalOcean Spaces for asset storage
4. Enable monitoring to track resource usage

## Security Checklist

- [ ] Strong passwords for database
- [ ] SSH keys only (no password auth)
- [ ] Firewall configured
- [ ] SSL certificates installed
- [ ] Security updates enabled
- [ ] Fail2ban configured
- [ ] Application secrets rotated
- [ ] Backup encryption enabled

## Support

For issues:
1. Check DigitalOcean status: status.digitalocean.com
2. Review logs and metrics
3. Consult documentation
4. Open support ticket with DigitalOcean