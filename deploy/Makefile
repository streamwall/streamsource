# StreamSource Deployment Makefile
# Usage: make [target] HOST=your-server-ip

HOST ?= your-droplet-ip
DEPLOY_USER = deploy
REPO_URL = git@github.com:YOUR_USERNAME/streamsource.git

.PHONY: help setup deploy rollback backup logs status restart

help:
	@echo "StreamSource Deployment Commands:"
	@echo "  make setup HOST=ip      - Initial server setup (run as root)"
	@echo "  make deploy HOST=ip     - Deploy latest code"
	@echo "  make rollback HOST=ip   - Rollback to previous release"
	@echo "  make backup HOST=ip     - Run manual backup"
	@echo "  make logs HOST=ip       - Tail application logs"
	@echo "  make status HOST=ip     - Check service status"
	@echo "  make restart HOST=ip    - Restart application"

setup:
	@echo "Setting up server at ${HOST}..."
	scp setup-droplet.sh root@${HOST}:/tmp/
	ssh root@${HOST} "chmod +x /tmp/setup-droplet.sh && /tmp/setup-droplet.sh"
	@echo "Setup complete! Next steps:"
	@echo "1. Set deploy user password: ssh root@${HOST} 'passwd deploy'"
	@echo "2. Copy SSH keys and configure deployment"

deploy:
	@echo "Deploying to ${HOST}..."
	ssh ${DEPLOY_USER}@${HOST} "/var/www/streamsource/deploy/deploy.sh"

rollback:
	@echo "Rolling back deployment on ${HOST}..."
	@ssh ${DEPLOY_USER}@${HOST} 'bash -s' < rollback.sh

backup:
	@echo "Running backup on ${HOST}..."
	ssh ${DEPLOY_USER}@${HOST} "sudo /usr/local/bin/backup.sh"

logs:
	@echo "Tailing logs on ${HOST}..."
	ssh ${DEPLOY_USER}@${HOST} "tail -f /var/www/streamsource/shared/log/production.log"

status:
	@echo "Checking status on ${HOST}..."
	@ssh ${DEPLOY_USER}@${HOST} 'bash -s' << 'SCRIPT'
	echo "=== Service Status ==="
	sudo systemctl status puma --no-pager
	echo -e "\n=== PostgreSQL Status ==="
	sudo systemctl status postgresql --no-pager | head -n 5
	echo -e "\n=== Redis Status ==="
	sudo systemctl status redis-server --no-pager | head -n 5
	echo -e "\n=== Disk Usage ==="
	df -h | grep -E "Filesystem|/$"
	echo -e "\n=== Memory Usage ==="
	free -h
	echo -e "\n=== Health Check ==="
	curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/health
	SCRIPT

restart:
	@echo "Restarting services on ${HOST}..."
	ssh ${DEPLOY_USER}@${HOST} "sudo systemctl restart puma && sudo systemctl reload nginx"
	@echo "Services restarted!"

# Development helpers
copy-configs:
	@echo "Copying configuration files to ${HOST}..."
	scp nginx.conf ${DEPLOY_USER}@${HOST}:/tmp/
	scp puma.service ${DEPLOY_USER}@${HOST}:/tmp/
	scp .env.production.template ${DEPLOY_USER}@${HOST}:/tmp/
	ssh ${DEPLOY_USER}@${HOST} "sudo mv /tmp/nginx.conf /etc/nginx/sites-available/streamsource"
	ssh ${DEPLOY_USER}@${HOST} "sudo mv /tmp/puma.service /etc/systemd/system/"

test-connection:
	@echo "Testing connection to ${HOST}..."
	ssh ${DEPLOY_USER}@${HOST} "echo 'Connection successful!'"