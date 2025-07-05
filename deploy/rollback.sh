#!/bin/bash
# Rollback to previous release

APP_ROOT="/var/www/streamsource"
CURRENT_RELEASE=$(readlink $APP_ROOT/current)
RELEASES_DIR="$APP_ROOT/releases"

echo "Current release: $CURRENT_RELEASE"

# Get previous release
PREVIOUS_RELEASE=$(ls -t $RELEASES_DIR | grep -v $(basename $CURRENT_RELEASE) | head -n 1)

if [ -z "$PREVIOUS_RELEASE" ]; then
    echo "No previous release found!"
    exit 1
fi

echo "Rolling back to: $PREVIOUS_RELEASE"
read -p "Are you sure? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -nfs "$RELEASES_DIR/$PREVIOUS_RELEASE" "$APP_ROOT/current"
    sudo systemctl restart puma
    echo "Rollback completed!"
else
    echo "Rollback cancelled."
fi