#!/bin/bash
set -e

# Configuration
APP_ROOT="/var/www/streamsource"
REPO_URL="git@github.com:YOUR_USERNAME/streamsource.git"
BRANCH="main"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RELEASE_DIR="$APP_ROOT/releases/$TIMESTAMP"
SHARED_DIR="$APP_ROOT/shared"
CURRENT_DIR="$APP_ROOT/current"

echo "Deploying StreamSource..."
echo "========================"

# Load rbenv
export RBENV_ROOT="/opt/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"

# Create release directory
echo "Creating release directory..."
mkdir -p "$RELEASE_DIR"

# Clone repository
echo "Cloning repository..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$RELEASE_DIR"

# Link shared files and directories
echo "Linking shared files..."
ln -nfs "$SHARED_DIR/.env.production" "$RELEASE_DIR/.env.production"
ln -nfs "$SHARED_DIR/config/master.key" "$RELEASE_DIR/config/master.key"
ln -nfs "$SHARED_DIR/log" "$RELEASE_DIR/log"
ln -nfs "$SHARED_DIR/tmp" "$RELEASE_DIR/tmp"
ln -nfs "$SHARED_DIR/public/system" "$RELEASE_DIR/public/system"

# Install dependencies
cd "$RELEASE_DIR"

echo "Installing Ruby dependencies..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

echo "Installing JavaScript dependencies..."
yarn install --frozen-lockfile

# Compile assets
echo "Compiling assets..."
RAILS_ENV=production bundle exec rails assets:precompile

# Run database migrations
echo "Running database migrations..."
RAILS_ENV=production bundle exec rails db:migrate

# Update current symlink
echo "Updating current symlink..."
ln -nfs "$RELEASE_DIR" "$CURRENT_DIR"

# Restart services
echo "Restarting services..."
sudo systemctl reload-or-restart puma
sudo systemctl reload nginx

# Clean up old releases (keep last 5)
echo "Cleaning up old releases..."
cd "$APP_ROOT/releases"
ls -t | tail -n +6 | xargs -r rm -rf

echo "Deployment completed successfully!"
echo ""
echo "Post-deployment checklist:"
echo "- Check application logs: tail -f $SHARED_DIR/log/production.log"
echo "- Check Puma logs: sudo journalctl -u puma -f"
echo "- Run health check: curl http://localhost/health"