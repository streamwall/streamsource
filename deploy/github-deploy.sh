#!/bin/bash
set -e

# GitHub Actions Deployment Script
# This script is called by GitHub Actions after tests pass

APP_ROOT="/var/www/streamsource"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RELEASE_DIR="$APP_ROOT/releases/$TIMESTAMP"
SHARED_DIR="$APP_ROOT/shared"
CURRENT_DIR="$APP_ROOT/current"
KEEP_RELEASES=5

echo "=== StreamSource GitHub Actions Deployment ==="
echo "Timestamp: $TIMESTAMP"

# Load rbenv
export RBENV_ROOT="/opt/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"

# Create release directory
echo "Creating release directory..."
mkdir -p "$RELEASE_DIR"

# Pull latest code from GitHub
echo "Pulling latest code..."
cd "$APP_ROOT"
git clone --depth 1 --branch main https://github.com/$GITHUB_REPOSITORY.git "$RELEASE_DIR"

# Link shared files
echo "Linking shared files..."
ln -nfs "$SHARED_DIR/.env.production" "$RELEASE_DIR/.env.production"
ln -nfs "$SHARED_DIR/config/master.key" "$RELEASE_DIR/config/master.key"
ln -nfs "$SHARED_DIR/log" "$RELEASE_DIR/log"
ln -nfs "$SHARED_DIR/tmp" "$RELEASE_DIR/tmp"
ln -nfs "$SHARED_DIR/public/system" "$RELEASE_DIR/public/system"
ln -nfs "$SHARED_DIR/storage" "$RELEASE_DIR/storage"

cd "$RELEASE_DIR"

# Install dependencies
echo "Installing Ruby dependencies..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle config set --local path "$SHARED_DIR/bundle"
bundle install --jobs 4

echo "Installing JavaScript dependencies..."
yarn install --frozen-lockfile --production

# Compile assets
echo "Compiling assets..."
RAILS_ENV=production bundle exec rails assets:precompile

# Run migrations
echo "Running database migrations..."
RAILS_ENV=production bundle exec rails db:migrate

# Update current symlink
echo "Switching to new release..."
OLD_RELEASE=$(readlink "$CURRENT_DIR" 2>/dev/null || echo "none")
ln -nfs "$RELEASE_DIR" "$CURRENT_DIR"

# Restart application
echo "Restarting application..."
sudo systemctl restart puma || true
sudo systemctl reload nginx || true

# Verify deployment
sleep 5
if curl -f -s -o /dev/null http://localhost/health; then
    echo "✅ Deployment successful!"
    
    # Clean up old releases
    echo "Cleaning up old releases..."
    cd "$APP_ROOT/releases"
    ls -t | tail -n +$((KEEP_RELEASES + 1)) | xargs -r rm -rf
else
    echo "❌ Health check failed! Rolling back..."
    if [ "$OLD_RELEASE" != "none" ]; then
        ln -nfs "$OLD_RELEASE" "$CURRENT_DIR"
        sudo systemctl restart puma
    fi
    exit 1
fi

echo "=== Deployment completed at $(date) ==="