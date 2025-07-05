#!/bin/bash

# This script sets up scheduled power on/off for the droplet
# to save costs during off-hours

echo "Setting up scheduled power management..."

# Create shutdown script
cat > /usr/local/bin/streamsource-shutdown.sh << 'EOF'
#!/bin/bash
# Gracefully stop services before shutdown
systemctl stop puma
systemctl stop nginx
systemctl stop postgresql
systemctl stop redis
# Shutdown the server
shutdown -h now
EOF

chmod +x /usr/local/bin/streamsource-shutdown.sh

# Create startup script (runs on boot)
cat > /etc/systemd/system/streamsource-startup.service << 'EOF'
[Unit]
Description=StreamSource Startup Tasks
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/streamsource-startup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/local/bin/streamsource-startup.sh << 'EOF'
#!/bin/bash
# Wait for network
sleep 10
# Start services
systemctl start postgresql
systemctl start redis
systemctl start puma
systemctl start nginx
# Optional: Send notification
# curl -X POST https://your-webhook-url -d "StreamSource server started"
EOF

chmod +x /usr/local/bin/streamsource-startup.sh
systemctl enable streamsource-startup.service

# Add cron jobs for automatic shutdown/startup
# Note: Startup requires DigitalOcean API or manual intervention
echo "Adding shutdown schedule to crontab..."

# Shutdown at 6 PM daily (adjust to your timezone)
(crontab -l 2>/dev/null; echo "0 18 * * * /usr/local/bin/streamsource-shutdown.sh") | crontab -

echo "Power management setup complete!"
echo ""
echo "IMPORTANT: For automatic startup, you need to:"
echo "1. Use DigitalOcean's scheduled snapshots with power-on"
echo "2. OR use their API to power on the droplet"
echo "3. OR manually start the droplet each morning"
echo ""
echo "Current schedule: Shutdown at 6:00 PM daily"
echo "Adjust the cron schedule as needed for your timezone"