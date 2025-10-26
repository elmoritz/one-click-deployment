# VPS Deployment Guide

This guide shows how to deploy your Hummingbird application to a VPS (Virtual Private Server).

## Prerequisites

- A VPS with Docker and Docker Compose installed
- SSH access to the VPS
- GitHub repository secrets configured

## Setup Steps

### 1. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

```
DEPLOY_HOST=your-server-ip
DEPLOY_USER=your-ssh-user
DEPLOY_KEY=your-private-ssh-key
DB_PASSWORD=your-database-password
```

### 2. Prepare VPS

SSH into your VPS and run:

```bash
# Create application directory
sudo mkdir -p /opt/hummingbird-app
sudo chown $USER:$USER /opt/hummingbird-app
cd /opt/hummingbird-app

# Create .env file
cat > .env << EOF
GITHUB_REPOSITORY=your-username/your-repo
DB_PASSWORD=your-secure-password
EOF

# Copy docker-compose.yml from your repository
```

### 3. Enable Deployment

In [.github/workflows/release.yml](../.github/workflows/release.yml), update the deploy job:

```yaml
deploy:
  name: Deploy Application
  runs-on: ubuntu-latest
  needs: [version, build-and-push, create-release]
  if: true  # Change from 'false' to 'true'

  steps:
    - name: Deploy to VPS
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.DEPLOY_KEY }}
        script: |
          cd /opt/hummingbird-app
          docker-compose pull
          docker-compose up -d

          # Wait for health check
          sleep 10
          docker-compose ps

          # Check logs for any errors
          docker-compose logs --tail=50 app
```

### 4. Setup Reverse Proxy (Optional but Recommended)

Install and configure Nginx or Caddy for HTTPS:

#### Using Caddy (Easiest)

```bash
# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Configure Caddy
sudo cat > /etc/caddy/Caddyfile << EOF
yourdomain.com {
    reverse_proxy localhost:8080
}
EOF

sudo systemctl restart caddy
```

#### Using Nginx

```bash
# Install Nginx and Certbot
sudo apt install -y nginx certbot python3-certbot-nginx

# Configure Nginx
sudo cat > /etc/nginx/sites-available/hummingbird << EOF
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/hummingbird /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com
```

## Monitoring

### View Application Logs

```bash
cd /opt/hummingbird-app
docker-compose logs -f app
```

### Check Application Status

```bash
docker-compose ps
curl http://localhost:8080/health
```

### Database Backup

```bash
# Backup
docker-compose exec postgres pg_dump -U hummingbird hummingbird > backup.sql

# Restore
docker-compose exec -T postgres psql -U hummingbird hummingbird < backup.sql
```

## Troubleshooting

### Container won't start

```bash
docker-compose logs app
docker-compose ps
```

### Database connection issues

```bash
docker-compose exec app env | grep DATABASE
docker-compose exec postgres pg_isready -U hummingbird
```

### Reset everything

```bash
docker-compose down -v
docker-compose up -d
```
