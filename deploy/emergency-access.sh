#!/bin/bash
# Emergency access script for GitHub Actions deployment issues

echo "=== Emergency Access Guide ==="
echo ""
echo "If GitHub Actions deployment is failing, use these manual steps:"
echo ""

echo "1. SSH into the server:"
echo "   ssh deploy@your-droplet-ip"
echo ""

echo "2. Pull latest changes manually:"
echo "   cd /var/www/streamsource/current"
echo "   git pull origin main"
echo ""

echo "3. Run deployment steps:"
cat << 'EOF'
   # Install dependencies
   bundle install --deployment --without development test
   yarn install --frozen-lockfile
   
   # Compile assets
   RAILS_ENV=production bundle exec rails assets:precompile
   
   # Run migrations
   RAILS_ENV=production bundle exec rails db:migrate
   
   # Restart services
   sudo systemctl restart puma
   sudo systemctl reload nginx
EOF
echo ""

echo "4. Check logs for errors:"
echo "   tail -f /var/www/streamsource/shared/log/production.log"
echo "   sudo journalctl -u puma -f"
echo ""

echo "5. Rollback if needed:"
echo "   /var/www/streamsource/deploy/rollback.sh"