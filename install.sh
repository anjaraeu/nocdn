#!/usr/bin/env bash
echo '  _   _        _____ _____  _   _ '
echo ' | \ | |      / ____|  __ \| \ | |'
echo ' |  \| | ___ | |    | |  | |  \| |'
echo ' | . ` |/ _ \| |    | |  | | ` ` |'
echo ' | |\  | (_) | |____| |__| | |\  |'
echo ' |_| \_|\___/ \_____|_____/|_| \_|'
echo 'This script will install a NoCDN instance on /srv/nocdn.'

function install_nginx {
apt install nginx
}

function install_config {
echo "Installing NoCDN files ..."
git clone https://github.com/nsaovh/nocdn /srv/nocdn
echo "Installing nginx config ..."
cp /srv/nocdn/conf/nocdn1.conf /etc/nginx/sites-enabled/nocdn1.conf
cp /srv/nocdn/conf/nocdn2.conf /etc/nginx/sites-enabled/nocdn2.conf
sed -i 's|domain.tld|$domain|' /etc/nginx/sites-enabled/nocdn1.conf

echo "Installing acme.sh ..."
git clone https://github.com/Neilpang/acme.sh /root/.acme.sh

echo "Generating certificates..."
/root/acme.sh/acme.sh --issue --webroot /srv/nocdn/public -k 4096 -d $domain
openssl req -x509 -newkey rsa:4096 -sha256 -utf8 -days 3650 -nodes -config /srv/nocdn/conf/openssl.conf -keyout /srv/nocdn/certs/key.pem -out /srv/nocdn/certs/cert.pem
echo "Restarting nginx ..."
systemctl restart nginx
}

function success {
echo "Congratulations, your nocdn instance is ready !"
}

echo "On which (sub)domain do you want to install NoCDN?"; read domain

read -r -p "Do you have already have nginx installed and include /etc/nginx/sites-enabled/* in your nginx.conf ? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
install_config
success
fi
if [[ "$response" =~ ^(no|n)$ ]] ; then
	install_nginx
	install_config
	success
fi
