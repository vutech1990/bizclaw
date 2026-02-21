#!/bin/bash
# BizClaw Landing Page Deployment Script
# Target: 116.118.2.98 (bizclaw.vn)

set -e

VPS_IP="116.118.2.98"
VPS_USER="root"
DOMAIN="bizclaw.vn"
LANDING_DIR="/var/www/bizclaw-landing"
NGINX_CONF="/etc/nginx/sites-available/bizclaw"

echo "🚀 Deploying BizClaw landing page to ${VPS_IP}..."

# Step 1: Create directory and copy files
echo "📁 Creating directory structure..."
ssh ${VPS_USER}@${VPS_IP} "mkdir -p ${LANDING_DIR}"

echo "📤 Uploading landing page..."
scp -r landing/index.html ${VPS_USER}@${VPS_IP}:${LANDING_DIR}/

# Step 2: Install Nginx if not present
echo "🔧 Setting up Nginx..."
ssh ${VPS_USER}@${VPS_IP} << 'REMOTE_SETUP'
# Install Nginx if needed
if ! command -v nginx &> /dev/null; then
    apt-get update && apt-get install -y nginx certbot python3-certbot-nginx
fi

# Create Nginx config
cat > /etc/nginx/sites-available/bizclaw << 'NGINX'
server {
    listen 80;
    server_name bizclaw.vn www.bizclaw.vn;

    root /var/www/bizclaw-landing;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip
    gzip on;
    gzip_types text/css application/javascript text/html application/json;
    gzip_min_length 256;

    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Landing page
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy to admin platform (future)
    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

# Enable site
ln -sf /etc/nginx/sites-available/bizclaw /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Test and reload
nginx -t && systemctl reload nginx

echo "✅ Nginx configured and reloaded!"
echo ""
echo "📍 Site available at: http://bizclaw.vn"
echo ""
echo "🔒 To enable HTTPS, run:"
echo "   certbot --nginx -d bizclaw.vn -d www.bizclaw.vn"

REMOTE_SETUP

echo ""
echo "🎉 Deployment complete!"
echo "   http://bizclaw.vn"
echo ""
echo "Next steps:"
echo "  1. Point DNS: bizclaw.vn → ${VPS_IP}"
echo "  2. Enable SSL: ssh root@${VPS_IP} 'certbot --nginx -d bizclaw.vn'"
