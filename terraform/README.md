# StreamSource Infrastructure

This directory contains Terraform configuration for deploying StreamSource to DigitalOcean with two deployment options.

## Architecture

### Option 1: App Platform (Default)
- **Database**: Managed PostgreSQL 15 cluster
- **Cache**: Managed Redis 7 cluster  
- **Application**: DigitalOcean App Platform
- **Region**: Configurable (default: nyc3)

### Option 2: Droplets (Traditional VPS)
- **Database**: Managed PostgreSQL 15 cluster
- **Cache**: Managed Redis 7 cluster
- **Application**: 2x Ubuntu 22.04 Droplets
- **Load Balancer**: DigitalOcean Load Balancer with SSL
- **Configuration**: Automated with Ansible

## Prerequisites

1. DigitalOcean account and API token
2. Terraform >= 1.0
3. GitHub repository with StreamSource code
4. For Droplets deployment: SSH key pair

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - `do_token`: Your DigitalOcean API token
   - `github_repo`: Your GitHub repository URL
   - `secret_key_base`: Generate with `rails secret`
   - `jwt_secret`: Generate with `rails secret`
   - `rails_master_key`: Copy from `config/master.key`
   - `use_droplets`: Set to `true` for Droplets deployment (default: `false`)
   - `ssh_public_key_path`: Path to your SSH public key (for Droplets)
   - `ssh_private_key_path`: Path to your SSH private key (for Droplets)

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Important Notes

### Database Configuration
- Uses DigitalOcean's default `doadmin` user
- Database name: `streamsource_production`
- Connection pooling handled by Rails (RAILS_MAX_THREADS)
- Automatic backups on Sunday and Wednesday
- Same database used for both deployment options

### Redis Configuration
- Eviction policy: `allkeys-lru` (suitable for caching)
- Used for both sessions (DB 0) and cache (DB 1)
- Rails handles database selection via REDIS_URL
- Same Redis cluster used for both deployment options

### Security Considerations
- All sensitive values stored as secrets (App Platform) or environment variables (Droplets)
- SSL/TLS enabled by default
- Database connections use SSL
- Health check endpoint excluded from SSL redirect
- Droplets: Firewall rules and fail2ban configured via Ansible

### Scaling
#### App Platform
- Adjust `app_instance_count` for horizontal scaling
- Adjust `app_instance_size` for vertical scaling

#### Droplets
- Adjust `droplet_count` for horizontal scaling
- Adjust `droplet_size` for vertical scaling
- Load balancer automatically distributes traffic

### Ansible Integration (Droplets Only)
When using Droplets deployment, Terraform automatically:
1. Creates the infrastructure
2. Generates Ansible inventory
3. Runs Ansible playbooks for configuration
4. Sets up monitoring and logging

## Outputs

After applying, Terraform will output:

### App Platform Deployment
- `app_url`: Your application URL
- `app_id`: App ID for CI/CD deployments
- Database and Redis connection details (marked as sensitive)

### Droplets Deployment
- `load_balancer_ip`: Load balancer public IP
- `droplet_ips`: Individual droplet IPs
- `app_url`: Your application URL (using load balancer)
- Database and Redis connection details (marked as sensitive)

## Maintenance

- Database maintenance: Sunday 2 AM UTC
- Redis maintenance: Sunday 3 AM UTC
- Backups: Sunday and Wednesday 4 AM UTC

## Troubleshooting

### Common Issues
1. **Database connection issues**: Check that the database name ends with `_production`
2. **Redis issues**: Ensure your app can handle Redis restarts during maintenance
3. **Deploy failures**: 
   - App Platform: Check build logs in DigitalOcean dashboard
   - Droplets: Check Ansible output and `/var/log/rails/production.log`

### Droplets-Specific
1. **SSH connection failed**: Ensure SSH key is added to ssh-agent
2. **Ansible playbook fails**: Check network connectivity and firewall rules
3. **Application not starting**: Review systemd logs with `journalctl -u rails`
4. **Asset compilation errors**: Check Node.js installation and yarn dependencies