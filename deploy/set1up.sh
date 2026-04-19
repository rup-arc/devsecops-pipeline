#!/bin/bash
# ============================================
# Jerney Blog Platform - EC2 Setup Script
# Path-safe version (NO HARDCODED DIRECTORY ISSUES)
# ============================================

set -e

echo "🛤️  Setting up Jerney Blog Platform..."
echo "==========================================="

# -----------------------------
# Detect script location + project root
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📁 Script directory: $SCRIPT_DIR"
echo "📁 Project root detected: $PROJECT_ROOT"

# -----------------------------
# Update system
# -----------------------------
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# -----------------------------
# Install Node.js 20.x
# -----------------------------
echo "📦 Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# -----------------------------
# Install PostgreSQL
# -----------------------------
echo "📦 Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# -----------------------------
# Install Nginx
# -----------------------------
echo "📦 Installing Nginx..."
sudo apt install -y nginx

# -----------------------------
# Install PM2
# -----------------------------
echo "📦 Installing PM2..."
sudo npm install -g pm2

# -----------------------------
# Configure PostgreSQL
# -----------------------------
echo "🗄️  Configuring PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE USER jerney_user WITH PASSWORD 'jerney_pass_2026';
CREATE DATABASE jerney_db OWNER jerney_user;
GRANT ALL PRIVILEGES ON DATABASE jerney_db TO jerney_user;
\c jerney_db
GRANT ALL ON SCHEMA public TO jerney_user;
EOF

echo "✅ PostgreSQL configured"

# -----------------------------
# Setup deployment directory
# -----------------------------
echo "📁 Setting up project..."
sudo mkdir -p /var/www/jerney
sudo chown -R $USER:$USER /var/www/jerney

# -----------------------------
# SAFE COPY (NO PATH ASSUMPTIONS)
# -----------------------------
echo "📦 Copying project files safely..."

if [ -d "$PROJECT_ROOT/backend" ] && [ -d "$PROJECT_ROOT/frontend" ]; then
    cp -r "$PROJECT_ROOT"/* /var/www/jerney/
else
    echo "❌ ERROR: backend/frontend folders not found in project root"
    echo "Detected root: $PROJECT_ROOT"
    exit 1
fi

# -----------------------------
# Backend setup
# -----------------------------
echo "📦 Installing backend dependencies..."
cd /var/www/jerney/backend
npm install --production

# -----------------------------
# Frontend build
# -----------------------------
echo "🔨 Building frontend..."
cd /var/www/jerney/frontend
npm install
npm run build

# -----------------------------
# Nginx configuration
# -----------------------------
echo "🌐 Configuring Nginx..."
sudo cp /var/www/jerney/deploy/jerney-nginx.conf /etc/nginx/sites-available/jerney
sudo ln -sf /etc/nginx/sites-available/jerney /etc/nginx/sites-enabled/jerney
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# -----------------------------
# Start backend with PM2 (safe restart)
# -----------------------------
echo "🚀 Starting backend with PM2..."
cd /var/www/jerney/backend

pm2 start src/index.js --name jerney-backend 2>/dev/null || pm2 restart jerney-backend
pm2 save
pm2 startup systemd -u $USER --hp /home/$USER | tail -1 | sudo bash

# -----------------------------
# Done
# -----------------------------
echo ""
echo "==========================================="
echo "🎉 Jerney is now live!"
echo "==========================================="

echo ""
echo "Access your blog at:"
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '<your-ec2-public-ip>')"

echo ""
echo "Useful commands:"
echo "  pm2 status"
echo "  pm2 logs"
echo "  pm2 restart all"
echo "  sudo systemctl restart nginx"
echo ""
