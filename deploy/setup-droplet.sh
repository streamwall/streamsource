#!/bin/bash
set -e

echo "StreamSource DigitalOcean Droplet Setup Script"
echo "=============================================="

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y \
  curl \
  git \
  build-essential \
  libpq-dev \
  postgresql \
  postgresql-contrib \
  redis-server \
  nginx \
  certbot \
  python3-certbot-nginx \
  imagemagick \
  libvips-tools \
  htop \
  fail2ban \
  ufw

# Install Node.js 24.x (required only when building assets on the host)
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y nodejs

# Install Yarn
npm install -g yarn

# Install Ruby using rbenv
echo "Installing Ruby..."
git clone https://github.com/rbenv/rbenv.git /opt/rbenv
git clone https://github.com/rbenv/ruby-build.git /opt/rbenv/plugins/ruby-build

echo 'export RBENV_ROOT="/opt/rbenv"' >> /etc/profile.d/rbenv.sh
echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
chmod +x /etc/profile.d/rbenv.sh

export RBENV_ROOT="/opt/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"

rbenv install 4.0.1
rbenv global 4.0.1

# Create deploy user
echo "Creating deploy user..."
useradd -m -s /bin/bash deploy
usermod -aG sudo deploy

# Setup PostgreSQL
echo "Setting up PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE USER streamsource WITH PASSWORD 'CHANGE_THIS_PASSWORD';
CREATE DATABASE streamsource_production OWNER streamsource;
ALTER USER streamsource CREATEDB;
EOF

# Configure PostgreSQL for password authentication
sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' /etc/postgresql/*/main/pg_hba.conf
systemctl restart postgresql

# Configure Redis
echo "Configuring Redis..."
sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
sed -i 's/# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
systemctl restart redis-server
systemctl enable redis-server

# Setup firewall
echo "Setting up firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

# Configure fail2ban
echo "Configuring fail2ban..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# Create application directory
echo "Creating application directory..."
mkdir -p /var/www/streamsource
chown deploy:deploy /var/www/streamsource

# Create shared directories
sudo -u deploy mkdir -p /var/www/streamsource/shared/{config,log,tmp/pids,tmp/cache,tmp/sockets,public/system}

echo "Basic setup complete!"
echo ""
echo "Next steps:"
echo "1. Set a password for the deploy user: passwd deploy"
echo "2. Copy your SSH key to the deploy user"
echo "3. Update the PostgreSQL password in the setup script"
echo "4. Run the deploy script as the deploy user"
echo "5. Configure your domain and SSL certificate"
