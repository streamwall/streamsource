# StreamSource Infrastructure

This directory contains Terraform configuration for deploying StreamSource to DigitalOcean.

## Architecture

- **Database**: Managed PostgreSQL 15 cluster
- **Cache**: Managed Redis 7 cluster  
- **Application**: DigitalOcean App Platform
- **Region**: Configurable (default: nyc3)

## Prerequisites

1. DigitalOcean account and API token
2. Terraform >= 1.0
3. GitHub repository with StreamSource code

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

### Redis Configuration
- Eviction policy: `allkeys-lru` (suitable for caching)
- Used for both sessions (DB 0) and cache (DB 1)
- Rails handles database selection via REDIS_URL

### Security Considerations
- All sensitive values stored as secrets
- SSL/TLS enabled by default
- Database connections use SSL
- Health check endpoint excluded from SSL redirect

### Scaling
- Adjust `app_instance_count` for horizontal scaling
- Adjust `app_instance_size` for vertical scaling
- Database and Redis can be scaled independently

## Outputs

After applying, Terraform will output:
- `app_url`: Your application URL
- `app_id`: App ID for CI/CD deployments
- Database and Redis connection details (marked as sensitive)

## Maintenance

- Database maintenance: Sunday 2 AM UTC
- Redis maintenance: Sunday 3 AM UTC
- Backups: Sunday and Wednesday 4 AM UTC

## Troubleshooting

1. **Database connection issues**: Check that the database name ends with `_production`
2. **Redis issues**: Ensure your app can handle Redis restarts during maintenance
3. **Deploy failures**: Check build logs in DigitalOcean App Platform dashboard