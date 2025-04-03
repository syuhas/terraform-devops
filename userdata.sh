#!/bin/bash
sudo yum update -y
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
cat > /usr/share/nginx/html/index.html <<EOF
${html}
EOF

sudo systemctl restart nginx
