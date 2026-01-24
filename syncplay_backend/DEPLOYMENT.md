# Ubuntu Deployment Guide with Nginx

Complete guide to deploy the SyncPlay backend on Ubuntu with Nginx and a custom domain.

---

## Prerequisites

- Ubuntu 20.04+ server
- Domain name pointing to your server IP
- SSH access with sudo privileges

---

## 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip python3-venv nginx redis-server postgresql postgresql-contrib certbot python3-certbot-nginx git
```

---

## 2. PostgreSQL Setup

```bash
# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE syncplay_db;
CREATE USER syncplay_user WITH PASSWORD 'your_secure_password';
ALTER ROLE syncplay_user SET client_encoding TO 'utf8';
ALTER ROLE syncplay_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE syncplay_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE syncplay_db TO syncplay_user;
\q
EOF
```

---

## 3. Redis Setup

```bash
sudo systemctl start redis
sudo systemctl enable redis

# Verify Redis is running
redis-cli ping  # Should return PONG
```

---

## 4. Application Setup

```bash
# Create app user
sudo useradd -m -s /bin/bash syncplay
sudo su - syncplay

# Clone repository
git clone https://github.com/khaled-muhammad/Syncy.git
cd Syncy/syncplay_backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install daphne psycopg2-binary

# Create .env file
cat > .env << EOF
SECRET_KEY=your-super-secret-key-change-this
DEBUG=False
DB_NAME=syncplay_db
DB_USER=syncplay_user
DB_PASSWORD=your_secure_password
DB_HOST=localhost
DB_PORT=5432
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
REDIS_URL=redis://127.0.0.1:6379/0
EOF

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser

exit  # Return to root
```

---

## 5. Systemd Service

```bash
sudo nano /etc/systemd/system/syncplay.service
```

Paste the following:

```ini
[Unit]
Description=SyncPlay Daphne Server
After=network.target postgresql.service redis.service

[Service]
User=syncplay
Group=syncplay
WorkingDirectory=/home/syncplay/Syncy/syncplay_backend
Environment="PATH=/home/syncplay/Syncy/syncplay_backend/venv/bin"
ExecStart=/home/syncplay/Syncy/syncplay_backend/venv/bin/daphne -u /run/syncplay/daphne.sock syncplay_backend.asgi:application
RuntimeDirectory=syncplay
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable syncplay
sudo systemctl start syncplay

# Check status
sudo systemctl status syncplay
```

---

## 6. Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/syncplay
```

Paste the following (replace `yourdomain.com`):

```nginx
upstream syncplay_server {
    server unix:/run/syncplay/daphne.sock fail_timeout=0;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    client_max_body_size 100M;

    location /static/ {
        alias /home/syncplay/Syncy/syncplay_backend/staticfiles/;
    }

    location / {
        proxy_pass http://syncplay_server;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

```bash
# Enable site and test config
sudo ln -s /etc/nginx/sites-available/syncplay /etc/nginx/sites-enabled/
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

---

## 7. SSL with Let's Encrypt

```bash
# Obtain SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal is set up automatically
# Test renewal
sudo certbot renew --dry-run
```

---

## 8. Firewall Setup

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw enable
```

---

## 9. Update Flutter App

Update `lib/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String baseDomain = 'yourdomain.com';
  static const String baseUrl = 'https://$baseDomain';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String wssBaseUrl = 'wss://$baseDomain/ws';
  // ...
}
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `sudo systemctl status syncplay` | Check app status |
| `sudo systemctl restart syncplay` | Restart app |
| `sudo journalctl -u syncplay -f` | View logs |
| `sudo nginx -t` | Test Nginx config |
| `sudo systemctl restart nginx` | Restart Nginx |

---

## Troubleshooting

**502 Bad Gateway:**
```bash
sudo journalctl -u syncplay -n 50
ls -la /run/syncplay/  # Check socket exists
```

**WebSocket not connecting:**
- Verify Nginx WebSocket headers
- Check firewall allows port 443
- Verify wss:// URL in Flutter app

**Permission denied:**
```bash
sudo chown -R syncplay:syncplay /home/syncplay/Syncy
sudo chmod 755 /run/syncplay
```
