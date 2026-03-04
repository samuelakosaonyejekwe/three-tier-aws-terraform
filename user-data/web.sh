#!/bin/bash
set -euxo pipefail

# Update packages
apt-get update -y

# Install Nginx and Git
apt-get install -y nginx git

# Create simple webpage
cat > /var/www/html/index.html <<'EOF'
<!doctype html>
<html>
<head><title>Web Tier</title></head>
<body>
<h1>Web Tier (Nginx) Running</h1>
<p>Requests to /api go to the app tier</p>
</body>
</html>
EOF

# Configure reverse proxy to internal ALB
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;

    location / {
        root /var/www/html;
        index index.html;
    }

    location /api/ {
        proxy_pass http://INTERNAL_ALB_DNS/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /health {
        return 200 "OK";
    }
}
EOF

systemctl enable nginx
systemctl restart nginx
