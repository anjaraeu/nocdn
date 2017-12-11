#!/usr/bin/env bash
echo '  _   _        _____ _____  _   _ '
echo ' | \ | |      / ____|  __ \| \ | |'
echo ' |  \| | ___ | |    | |  | |  \| |'
echo ' | . ` |/ _ \| |    | |  | | ` ` |'
echo ' | |\  | (_) | |____| |__| | |\  |'
echo ' |_| \_|\___/ \_____|_____/|_| \_|'
echo 'This script will install a NoCDN instance on /opt/nocdn on debian.'

function install_nginx {
apt install nginx
}

function git_clone {
git clone https://github.com/nsaovh/nocdn /opt/nocdn
}

function install_config {
echo "Generating certificates..."
git clone https://github.com/Neilpang/acme.sh /root/.acme.sh
	echo 'server {
	listen 80;
	server_name domain.tld;
	location / { return 301 https://$host$request_uri; }
	location /.well-known/acme-challenge/ { allow all; }
	root /opt/nocdn;
}

#server {
#	listen 443 ssl http2;
#	server_name domain.tld;

#	index index.html index.php;
#	charset utf-8;
#	client_max_body_size 10M;

#	ssl_certificate /chemin/vers/la/fullchain.cer;
#	ssl_certificate_key /chemin/vers/la/certificate.key;

#	include /etc/nginx/conf.d/ciphers.conf;

#	access_log /var/log/nginx/access.log combined;
#	error_log /var/log/nginx/error.log error;

#	error_page 500 502 503 504 /50x.html;
#	root /chemin/vers/le/directory;

#	location = /favicon.ico {
#		access_log off;
#		log_not_found off;
#	}

#	location ~ \.php$ {
#		include snippets/fastcgi-php.conf;
#		fastcgi_pass unix:/run/php/php7.0-fpm.sock;
#
#}

#	location ~* \.(jpg|jpeg|gif|css|png|js|map|woff|woff2|ttf|svg|eot)$ {
#		expires 30d;
#		access_log off;
#	}

#	location ~* \.(eot|ttf|woff|svg)$ {
#		add_header Acccess-Control-Allow-Origin *;
#	}
#}

' > /etc/nginx/sites-available
/root/acme.sh/acme.sh --issue --webroot /opt/nocdn -k 4096 -d $domain
}

echo "On which sub)domain do you want to install NoCDN?"
read domain

read -r -p "Do you have already have nginx installed and include /etc/nginx/sites-enabled? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]]

