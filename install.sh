#!/bin/bash
IPV4=$(curl -s -4 ip.sb)
apt update \
&& apt install nginx -y \
&& apt install jq -y \
&& mkdir -p /var/www/html/.well-known/pki-validation \
&& mkdir -p /etc/nginx/ssl \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/nginx.conf -O /etc/nginx/nginx.conf \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/default /etc/nginx/conf.d/default \
&& wget https://raw.githubusercontent.com/viva9grup/cpip/main/create-csr.sh /etc/nginx/ssl/ \
&& rm -rf /etc/nginx/site* \
&& service nginx reload \
&& cd /etc/nginx/ssl \
&& openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048 \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/create-csr.sh \
&& bash create-csr.sh \
&& wget -q https://raw.githubusercontent.com/viva9grup/cpip/main/ips.conf -O /etc/nginx/conf.d/$IPV4.conf \
&& rm default \
&& wget https://raw.githubusercontent.com/viva9grup/cpip/main/robots.txt -O /var/www/html/robots.txt

echo -n "Backend IP: "
read -r BACKEND

echo -n "Backend Port: "
read -r PORT

sed -i "s/#BACKEND/${BACKEND}/g" /etc/nginx/conf.d/$IPV4.conf \
&& sed -i "s/#PORT/${PORT}/g" /etc/nginx/conf.d/$IPV4.conf \
&& sed -i "s/#IP/${IPV4}/g" /etc/nginx/conf.d/$IPV4.conf \
&& service nginx reload \
&& curl -I https://$IPV4
