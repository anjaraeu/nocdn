#!/usr/bin/env bash
echo '  _   _        _____ _____  _   _ '
echo ' | \ | |      / ____|  __ \| \ | |'
echo ' |  \| | ___ | |    | |  | |  \| |'
echo ' | . ` |/ _ \| |    | |  | | ` ` |'
echo ' | |\  | (_) | |____| |__| | |\  |'
echo ' |_| \_|\___/ \_____|_____/|_| \_|'
echo 'This script will install a NoCDN instance on /srv/nocdn.'

function install_nginx_debian {
if [ "$version" = "9.*" ]
then
	apt install nginx -y
fi
if [ "$version" = "8.*" ]
then
	echo "The nginx package from Debian Jessie Depots is too old (1.6.2)"
	echo ""
	read -r -p "Are the jessie backports already installed ? [y/N] " response
	response=${response,,}    # tolower
	if [[ "$response" =~ ^(yes|y)$ ]] ; then
		apt-get -t jessie-backports install nginx -y
	fi
	if [[ "$response" =~ ^(no|n)$ ]] ; then
		echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list
		apt-get update
		apt-get -t jessie-backports install nginx -y
	fi
fi


}

function install_nginx_arch {
	pacman -S nginx --noconfirm
}

function le_certs {
	# temp config for LE's first verification
	cp /srv/nocdn/conf/nocdn1_temp.conf /etc/nginx/sites-enabled/nocdn1_temp.conf
	sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1_temp.conf
	
	read -r -p "Is acme.sh already installed in /root/.acme.sh ? [y/N] " response
	response=${response,,}    # tolower
	if [[ "$response" =~ ^(yes|y)$ ]] ; then
		echo "Generating Let's Encrypt certificate ..."
		/root/.acme.sh/acme.sh --issue --nginx -k 4096 -d $domain
		rm /etc/nginx/sites-enabled/nocdn1_temp.conf
		cp /srv/nocdn/conf/nocdn1.conf /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		echo "Restarting nginx ..."
		systemctl restart nginx
	fi
	if [[ "$response" =~ ^(no|n)$ ]] ; then
		echo "Installing acme.sh ..."
		git clone https://github.com/Neilpang/acme.sh /root/.acme.sh
		echo "Generating Let's Encrypt certificate ..."
		/root/acme.sh/acme.sh --issue --nginx -k 4096 -d $domain
		rm /etc/nginx/sites-enabled/nocdn1_temp.conf
		cp /srv/nocdn/conf/nocdn1.conf /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		echo "Restarting nginx ..."
		systemctl restart nginx
	fi
}

function install_config_1 {
	echo "Installing NoCDN files ..."
	mkdir /srv
	git clone https://github.com/nsaovh/nocdn /srv/nocdn
	echo "Installing nginx config ..."
	mkdir -p /etc/nginx/conf.d
	# TLS configuration
	cp /srv/nocdn/conf/ciphers.conf /etc/nginx/conf.d/ciphers.conf

	cp /srv/nocdn/conf/nocdn2.conf /etc/nginx/sites-enabled/nocdn2.conf
	sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1_temp.conf
	echo "Generating self-signed certificate ..."
	openssl req -x509 -newkey rsa:4096 -sha256 -utf8 -days 3650 -nodes -config /srv/nocdn/conf/openssl.conf -keyout /srv/nocdn/certs/key.pem -out /srv/nocdn/certs/cert.pem
	systemctl restart nginx

}


function start_debian {
apt update && apt full-upgrade -y
apt install git
echo "On which (sub)domain do you want to install NoCDN?"; read -r domain

read -r -p "Do you have already have nginx installed and include /etc/nginx/sites-enabled/* in your nginx.conf ? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
install_config
success
exit 1
fi
if [[ "$response" =~ ^(no|n)$ ]] ; then
	install_nginx_debian
	install_config
	success
	exit 1
fi
}

function start_arch {
	pacman -Syu
	pacman -S git --noconfirm
	echo "On which (sub)domain do you want to install NoCDN?"; read -r domain

	read -r -p "Do you have already have nginx installed and include /etc/nginx/sites-enabled/* in your nginx.conf ? [y/N] " response
	response=${response,,}    # tolower
	if [[ "$response" =~ ^(yes|y)$ ]] ; then
		install_config
		success
	exit 1
	fi
	if [[ "$response" =~ ^(no|n)$ ]] ; then
		install_nginx_arch
		install_config
		success
		exit 1
	fi
}

function success {
echo "Congratulations, your nocdn instance is ready !"
}

os=$(lsb_release -is)
version=$(lsb_release -rs)
echo "It seems that you are running" $os $version

if [[ "$os" == "Debian" ]];
then
if [ "$version" -lt 8.* ];
then
	echo "Seriously ? Debian" $version "? Please consider to upgrade ..."
	exit 1
fi
	start_debian
else
if [[ "$os" == "Arch" ]]; 
then
	start_arch
else
	echo "Sorry, but at the moment, we only support Debian and Arch."
	exit 1
fi
fi
