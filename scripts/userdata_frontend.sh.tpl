#!/bin/bash
set -euxo pipefail

yum update -y
yum install -y nginx jq awscli

BACKEND_LB_NAME="${backend_nlb_name}"
REGION="${aws_region}"
BACKEND_DNS="$(aws elbv2 describe-load-balancers --region "$REGION" --names "$BACKEND_LB_NAME" --query 'LoadBalancers[0].DNSName' --output text || true)"

if [ -z "$BACKEND_DNS" ] || [ "$BACKEND_DNS" = "None" ]; then
  BACKEND_DNS="localhost"
fi

cat > /etc/nginx/conf.d/default.conf <<NGINXCONF
server {
  listen 80;
  server_name _;

  location / {
    proxy_pass http://$BACKEND_DNS:8080;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
NGINXCONF

systemctl enable nginx
systemctl restart nginx

/opt/aws/bin/cfn-signal --success true || true
