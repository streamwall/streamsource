#!/bin/bash
set -euo pipefail

# StreamSource Deployment Script
# Usage: ./scripts/deploy.sh [environment] [deployment_type]
# Example: ./scripts/deploy.sh production app-platform
# Example: ./scripts/deploy.sh staging droplets

ENVIRONMENT=${1:-production}
DEPLOYMENT_TYPE=${2:-auto}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check for required tools
    for tool in git doctl ansible terraform; do
        if ! command -v $tool &> /dev/null; then
            error "$tool is not installed. Please install it first."
        fi
    done
    
    # Check for required environment variables
    if [[ "$DEPLOYMENT_TYPE" == "app-platform" || "$DEPLOYMENT_TYPE" == "auto" ]]; then
        if [[ -z "${DO_APP_ID:-}" ]]; then
            error "DO_APP_ID environment variable is not set"
        fi
    fi
    
    if [[ -z "${DIGITALOCEAN_ACCESS_TOKEN:-}" ]]; then
        error "DIGITALOCEAN_ACCESS_TOKEN environment variable is not set"
    fi
}

# Detect deployment type
detect_deployment_type() {
    if [[ "$DEPLOYMENT_TYPE" == "auto" ]]; then
        log "Auto-detecting deployment type..."
        
        # Check if we have an app ID
        if [[ -n "${DO_APP_ID:-}" ]]; then
            DEPLOYMENT_TYPE="app-platform"
        else
            # Check if we have droplets
            if doctl compute droplet list --tag-name streamsource --format ID --no-header | grep -q .; then
                DEPLOYMENT_TYPE="droplets"
            else
                error "Could not detect deployment type. Please specify 'app-platform' or 'droplets'"
            fi
        fi
        
        log "Detected deployment type: $DEPLOYMENT_TYPE"
    fi
}

# Run tests
run_tests() {
    log "Running tests..."
    cd "$PROJECT_ROOT"
    
    # Run tests in Docker
    docker compose run --rm -e RAILS_ENV=test web bin/test
    
    if [[ $? -ne 0 ]]; then
        error "Tests failed. Aborting deployment."
    fi
    
    log "Tests passed!"
}

# Deploy to App Platform
deploy_app_platform() {
    log "Deploying to DigitalOcean App Platform ($ENVIRONMENT)..."
    
    # Authenticate with DigitalOcean
    doctl auth init -t "$DIGITALOCEAN_ACCESS_TOKEN"
    
    # Get app ID based on environment
    local app_id
    if [[ "$ENVIRONMENT" == "production" ]]; then
        app_id="${DO_APP_ID}"
    else
        app_id="${DO_STAGING_APP_ID:-$DO_APP_ID}"
    fi
    
    # Update app spec
    local spec_file=".do/app.yaml"
    if [[ "$ENVIRONMENT" == "staging" && -f ".do/app.staging.yaml" ]]; then
        spec_file=".do/app.staging.yaml"
    fi
    
    log "Updating app with spec: $spec_file"
    doctl apps update "$app_id" --spec "$spec_file" --wait
    
    # Run migrations
    log "Running database migrations..."
    doctl apps run "$app_id" web -- bundle exec rails db:migrate RAILS_ENV="$ENVIRONMENT"
    
    # Get app URL
    local app_url=$(doctl apps get "$app_id" --format DefaultIngress --no-header)
    log "App deployed to: https://$app_url"
    
    # Health check
    sleep 30
    if curl -f "https://$app_url/health" &> /dev/null; then
        log "Health check passed!"
    else
        error "Health check failed!"
    fi
}

# Deploy to Droplets
deploy_droplets() {
    log "Deploying to Droplets ($ENVIRONMENT)..."
    
    cd "$PROJECT_ROOT/ansible"
    
    # Generate inventory if needed
    if [[ ! -f "inventory/$ENVIRONMENT.yml" ]]; then
        log "Generating Ansible inventory..."
        
        # Get droplet IPs
        local droplet_ips=$(doctl compute droplet list --tag-name "streamsource-$ENVIRONMENT" --format PublicIPv4 --no-header)
        
        if [[ -z "$droplet_ips" ]]; then
            error "No droplets found for environment: $ENVIRONMENT"
        fi
        
        # Create inventory file
        cat > "inventory/$ENVIRONMENT.yml" << EOF
all:
  vars:
    app_name: streamsource
    app_user: rails
    app_path: /home/rails/streamsource
    github_branch: ${GITHUB_BRANCH:-main}
    environment: $ENVIRONMENT
  children:
    app_servers:
      hosts:
EOF
        
        # Add droplet IPs
        local i=1
        while IFS= read -r ip; do
            echo "        app-$i:" >> "inventory/$ENVIRONMENT.yml"
            echo "          ansible_host: $ip" >> "inventory/$ENVIRONMENT.yml"
            ((i++))
        done <<< "$droplet_ips"
    fi
    
    # Run deployment playbook
    log "Running Ansible deployment..."
    ansible-playbook deploy.yml \
        --inventory "inventory/$ENVIRONMENT.yml" \
        --extra-vars "deployment_environment=$ENVIRONMENT"
    
    # Health check
    log "Running health checks..."
    local droplet_ips=$(doctl compute droplet list --tag-name "streamsource-$ENVIRONMENT" --format PublicIPv4 --no-header)
    
    while IFS= read -r ip; do
        if curl -f "http://$ip/health" &> /dev/null; then
            log "Health check passed for $ip"
        else
            error "Health check failed for $ip"
        fi
    done <<< "$droplet_ips"
}

# Rollback deployment
rollback() {
    log "Rolling back deployment..."
    
    if [[ "$DEPLOYMENT_TYPE" == "app-platform" ]]; then
        # App Platform rollback
        local app_id="${DO_APP_ID}"
        local deployments=$(doctl apps list-deployments "$app_id" --format ID --no-header | head -2)
        local previous_deployment=$(echo "$deployments" | tail -1)
        
        if [[ -n "$previous_deployment" ]]; then
            log "Rolling back to deployment: $previous_deployment"
            doctl apps create-deployment "$app_id" --force-rebuild
        else
            error "No previous deployment found"
        fi
    else
        # Droplet rollback using Ansible
        cd "$PROJECT_ROOT/ansible"
        ansible-playbook rollback.yml \
            --inventory "inventory/$ENVIRONMENT.yml" \
            --extra-vars "deployment_environment=$ENVIRONMENT"
    fi
}

# Main deployment flow
main() {
    log "Starting deployment to $ENVIRONMENT..."
    
    check_prerequisites
    detect_deployment_type
    
    # Confirm deployment
    read -p "Deploy to $ENVIRONMENT using $DEPLOYMENT_TYPE? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Deployment cancelled"
        exit 0
    fi
    
    # Run tests if not skipped
    if [[ "${SKIP_TESTS:-}" != "true" ]]; then
        run_tests
    else
        warning "Skipping tests (SKIP_TESTS=true)"
    fi
    
    # Deploy based on type
    case "$DEPLOYMENT_TYPE" in
        app-platform)
            deploy_app_platform
            ;;
        droplets)
            deploy_droplets
            ;;
        *)
            error "Unknown deployment type: $DEPLOYMENT_TYPE"
            ;;
    esac
    
    log "Deployment completed successfully!"
    
    # Send notification
    if [[ -n "${SLACK_WEBHOOK:-}" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"StreamSource deployed to $ENVIRONMENT successfully!\"}" \
            "$SLACK_WEBHOOK"
    fi
}

# Handle errors
trap 'error "Deployment failed on line $LINENO"' ERR

# Run main function
main "$@"