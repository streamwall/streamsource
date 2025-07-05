#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/var/backups/streamsource"
DB_NAME="streamsource_production"
DB_USER="streamsource"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting backup at $(date)"

# Backup database
echo "Backing up database..."
export PGPASSWORD="$DB_PASSWORD"
pg_dump -U "$DB_USER" -h localhost "$DB_NAME" | gzip > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz"

# Backup uploaded files
echo "Backing up uploaded files..."
if [ -d "/var/www/streamsource/shared/public/system" ]; then
  tar -czf "$BACKUP_DIR/uploads_backup_$TIMESTAMP.tar.gz" -C /var/www/streamsource/shared/public system
fi

# Backup environment files
echo "Backing up configuration..."
tar -czf "$BACKUP_DIR/config_backup_$TIMESTAMP.tar.gz" \
  -C /var/www/streamsource/shared \
  .env.production \
  config/master.key 2>/dev/null || true

# Clean up old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed at $(date)"

# Optional: Upload to DigitalOcean Spaces
# Uncomment and configure if using DO Spaces for offsite backup
# echo "Uploading to DigitalOcean Spaces..."
# s3cmd put "$BACKUP_DIR/*_$TIMESTAMP.*" s3://your-space-name/backups/