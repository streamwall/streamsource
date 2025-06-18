#!/bin/bash
set -euo pipefail

# Generate Ansible inventory from DigitalOcean droplets
# Usage: ./scripts/generate-inventory.sh [environment]

ENVIRONMENT=${1:-production}
INVENTORY_DIR="ansible/inventory"
INVENTORY_FILE="$INVENTORY_DIR/$ENVIRONMENT.yml"

# Create inventory directory if it doesn't exist
mkdir -p "$INVENTORY_DIR"

# Get droplet information
echo "Fetching droplet information for environment: $ENVIRONMENT"

# Get droplets with the appropriate tag
DROPLETS=$(doctl compute droplet list --tag-name "streamsource-$ENVIRONMENT" --format "Name,PublicIPv4" --no-header)

if [[ -z "$DROPLETS" ]]; then
    echo "No droplets found with tag: streamsource-$ENVIRONMENT"
    exit 1
fi

# Start building inventory file
cat > "$INVENTORY_FILE" << EOF
---
all:
  vars:
    app_name: streamsource
    app_user: rails
    app_path: /home/rails/streamsource
    ruby_version: 3.3.6
    nodejs_version: 20
    
    # Environment
    rails_env: $ENVIRONMENT
    
    # Secrets from environment/GitHub secrets
    database_url: "\${DATABASE_URL}"
    redis_url: "\${REDIS_URL}"
    secret_key_base: "\${SECRET_KEY_BASE}"
    rails_master_key: "\${RAILS_MASTER_KEY}"
    jwt_secret: "\${JWT_SECRET}"
    
    # Git configuration
    github_repo: "\${GITHUB_REPOSITORY:-https://github.com/yourusername/streamsource.git}"
    github_branch: "\${GITHUB_REF_NAME:-main}"
    
    # Performance
    rails_max_threads: 5
    web_concurrency: 2
    
  children:
    app_servers:
      hosts:
EOF

# Add droplets to inventory
echo "$DROPLETS" | while IFS=$'\t' read -r name ip; do
    cat >> "$INVENTORY_FILE" << EOF
        $name:
          ansible_host: $ip
EOF
done

echo "Generated inventory file: $INVENTORY_FILE"
echo "Contents:"
cat "$INVENTORY_FILE"