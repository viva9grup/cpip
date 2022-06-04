#!/bin/bash
echo -n "Backend IP: "
read -r BACKEND

echo -n "Backend Port: "
read -r PORT

IPV4=$(curl -s -4 ip.sb)
apt update \
&& apt install nginx -y \
&& systemctl enable nginx \
&& systemctl start nginx \
&& apt install jq unzip -y \
&& mkdir -p /var/www/html/.well-known/pki-validation \
&& rm -rf /etc/nginx/site* \
&& mkdir -p /etc/nginx/ssl \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/nginx.conf -O /etc/nginx/nginx.conf \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/default -O /etc/nginx/conf.d/default \
&& service nginx restart \
&& echo "Generate SSL Pharam" \
&& openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048 \
&& sed -i 's/RANDFILE.*ENV.*//g' /etc/ssl/openssl.cnf \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/create-csr.sh -O /etc/nginx/ssl/create-csr.sh \
&& bash /etc/nginx/ssl/create-csr.sh \
&& rm /etc/nginx/conf.d/default \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/ips.conf -O /etc/nginx/conf.d/$IPV4.conf \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/robots.txt -O /var/www/html/robots.txt \
&& sed -i "s/#BACKEND/${BACKEND}/g" /etc/nginx/conf.d/$IPV4.conf \
&& sed -i "s/#PORT/${PORT}/g" /etc/nginx/conf.d/$IPV4.conf \
&& sed -i "s/#IP/${IPV4}/g" /etc/nginx/conf.d/$IPV4.conf \
&& service nginx reload \
&& curl -I https://$IPV4
