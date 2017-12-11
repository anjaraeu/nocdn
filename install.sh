#!/usr/bin/env bash
echo '  _   _        _____ _____  _   _ '
echo ' | \ | |      / ____|  __ \| \ | |'
echo ' |  \| | ___ | |    | |  | |  \| |'
echo ' | . ` |/ _ \| |    | |  | | ` ` |'
echo ' | |\  | (_) | |____| |__| | |\  |'
echo ' |_| \_|\___/ \_____|_____/|_| \_|'
echo 'This script will install a NoCDN instance on /srv/nocdn on debian.'

function install_nginx {
apt install nginx
}

function git_clone {
git clone https://github.com/nsaovh/nocdn /srv/nocdn
}

function install_config {
echo "Generating certificates..."
git clone https://github.com/Neilpang/acme.sh /root/.acme.sh
cp /srv/nocdn/conf/nginx_sample_nocdn_1.conf /etc/nginx/sites-enabled/nocdn1.conf
cp /srv/nocdn/conf/nginx_sample_nocdn_2.conf /etc/nginx/sites-enabled/nocdn2.conf
/root/acme.sh/acme.sh --issue --webroot /srv/nocdn/public -k 4096 -d $domain
}

echo "On which (sub)domain do you want to install NoCDN?"; read domain

read -r -p "Do you have already have nginx installed and include /etc/nginx/sites-enabled/*? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
install_config
fi
if [[ "$response" =~ ^(no|n)$ ]] ; then
	install_nginx
	install_config
fi
