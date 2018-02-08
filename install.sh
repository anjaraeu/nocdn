#!/usr/bin/env bash
GREEN='\033[0;32m'
RED='\033[0;33m'
NC='\033[0m'
echo -e ${GREEN}
echo -e '  _   _        _____ _____  _   _ '
echo -e ' | \ | |      / ____|  __ \| \ | |'
echo -e ' |  \| | ___ | |    | |  | |  \| |'
echo -e ' | . ` |/ _ \| |    | |  | | ` ` |'
echo -e ' | |\  | (_) | |____| |__| | |\  |'
echo -e ' |_| \_|\___/ \_____|_____/|_| \_|'
echo -e 'This script will install a NoCDN instance on /srv/nocdn.'
echo -e ${NC}

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 1>&2
   exit 1
fi


function install_nginx_debian {
if [ "$version" = "testing" ]
then
    echo -e "${RED}Warning! Using debian testing might not work${NC}"
    apt install nginx -y
fi
if [ "$version" = "9.*" ]
then
	apt install nginx -y
fi
if [ "$version" = "8.*" ]
then
	echo -e "${GREEN}The nginx package from Debian Jessie Depots is too old (1.6.2)${NC}"
	echo -e ""
	echo -e "${GREEN}Are the jessie backports already installed ? [y/N] ${NC}"; read -r response
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

function choice-le-selfsigned {
	# leorsf means Let's encrypt or self-signed
	echo -e "${GREEN}For the 'Fantom cdn' part, a self-signed certificate will be used, (we can't issue a cert from a trusted CA for the CDNs), but you  can use a Let's encrypt certificate for the public part."
	echo -e "Do you want to generate and use self-signed certificates or use a Let's Encrypt one ? [LE/selfsigned]${NC}"; read -r leorsf

if [[ "$leorsf" =~ ^(LE|le)$ ]] ; then
	le_certs
else
	if [[ "$leorsf" == "selfsigned" ]]; then
		selfsigned_certs
	fi
fi

}

function install_nginx_arch {
	pacman -Sy nginx --noconfirm
}

function le_certs {
	# temp config for LE's first verification
	cp /srv/nocdn/conf/nocdn1_temp.conf /etc/nginx/sites-enabled/nocdn1_temp.conf
	sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1_temp.conf

	echo -e "${GREEN}Is acme.sh already installed in /root/.acme.sh ? [y/N] ${NC}" ; read -r response
	response=${response,,}    # tolower
	if [[ "$response" =~ ^(yes|y)$ ]] ; then
		echo -e "${GREEN}Generating Let's Encrypt certificate ...${NC}"
		/root/.acme.sh/acme.sh --issue --nginx -k 4096 -d $domain
		rm /etc/nginx/sites-enabled/nocdn1_temp.conf
		cp /srv/nocdn/conf/nocdn1.conf /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		echo -e "${GREEN}Generating the fantom self-signed certificate ...${NC}"
		openssl req -x509 -newkey rsa:4096 -sha256 -utf8 -days 3650 -nodes -config /srv/nocdn/conf/openssl_fantom.conf -keyout /srv/nocdn/certs/fantom_key.pem -out /srv/nocdn/certs/fantom_cert.pem
		echo -e "${GREEN}Restarting nginx ... ${NC}"
		systemctl restart nginx
		install_config_2_le
	fi
	if [[ "$response" =~ ^(no|n)$ ]] ; then
		echo -e "${GREEN}Installing acme.sh ...${NC}"
		git clone https://github.com/Neilpang/acme.sh /root/.acme.sh
		echo -e "${GREEN}Generating Let's Encrypt certificate ...${NC}"
		/root/acme.sh/acme.sh --issue --nginx -k 4096 -d $domain
		rm /etc/nginx/sites-enabled/nocdn1_temp.conf
		cp /srv/nocdn/conf/nocdn1.conf /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1.conf
		echo -e "${GREEN}Generating the fantom self-signed certificate ...${NC}"
		openssl req -x509 -newkey rsa:4096 -sha256 -utf8 -days 3650 -nodes -config /srv/nocdn/conf/openssl_fantom.conf -keyout /srv/nocdn/certs/fantom_key.pem -out /srv/nocdn/certs/fantom_cert.pem
		echo -e "${GREEN}Restarting nginx ...${NC}"
		systemctl restart nginx
		install_config_2_le
	fi
}


function selfsigned_certs {
	echo -e "${GREEN}Generating the public self-signed certificate ...${NC}"
	sed -i "s|domain.tld|$domain|" /srv/nocdn/conf/openssl_public.conf
	openssl req -x509 -newkey rsa:4096 -sha256 -utf8 -days 3650 -nodes -config /srv/nocdn/conf/openssl_public.conf -keyout /srv/nocdn/certs/public_key.pem -out /srv/nocdn/certs/public_cert.pem
	echo -e "${GREEN}Generating the fantom self-signed certificate ...${NC}"
	openssl req -x509 -newkey rsa:4096 -sha256 -utf8 -days 3650 -nodes -config /srv/nocdn/conf/openssl_fantom.conf -keyout /srv/nocdn/certs/fantom_key.pem -out /srv/nocdn/certs/fantom_cert.pem
	install_config_2_selfsigned
}

function install_config_1 {
	echo -e "${GREEN}* Installing NoCDN's files ...${NC}"
	# this dir should exists by default, though it mabye not, so
	mkdir /srv
	git clone https://github.com/nsaovh/nocdn /srv/nocdn
	echo -e "${GREEN}* Installing nginx config ...${NC}"
	# same as /srv
	mkdir -p /etc/nginx/conf.d
	# TLS configuration
	cp /srv/nocdn/conf/ciphers.conf /etc/nginx/conf.d/ciphers.conf

	# Create certs dir for selfsigned certs.

	mkdir -p /srv/nocdn/certs

	# Nginx config for the fantoms CDNs
	cp /srv/nocdn/conf/nocdn2.conf /etc/nginx/sites-enabled/nocdn2.conf

	# generate certs
	choice-le-selfsigned
}

function install_config_2_le {
	rm /etc/nginx/sites-enabled/nocdn1_temp.conf
	cp /srv/nocdn/conf/nocdn1.conf /etc/nginx/sites-enabled/nocdn1_le.conf
	sed -i "s|domain.tld|$domain|" /etc/nginx/sites-enabled/nocdn1_le.conf
	sed -i "s|domain.tld.key|$domain.key|" /etc/nginx/sites-enabled/nocdn1_le.conf
	systemctl restart nginx
}

function install_config_2_selfsigned {
	cp /srv/nocdn/conf/nocdn1_selfsigned.conf /etc/nginx/sites-enabled/nocdn1_selfsigned.conf
	systemctl restart nginx
}


function start_debian {
apt update && apt full-upgrade -y
apt install git
echo -e "${GREEN}On which (sub)domain do you want to install NoCDN?${NC}"; read -r domain

echo -e "${GREEN}Do you have already have nginx installed and include /etc/nginx/sites-enabled/* in your nginx.conf ? [y/N] ${NC}"; read -r response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
install_config_1
success
exit 1
fi
if [[ "$response" =~ ^(no|n)$ ]] ; then
	install_nginx_debian
	install_config_1
	success
	exit 1
fi
}

function start_arch {
	pacman -Syu
	pacman -S git --noconfirm
	echo -e "${GREEN}On which (sub)domain do you want to install NoCDN?${NC}"; read -r domain

	echo -e "${GREEN}Do you have already have nginx installed and include /etc/nginx/sites-enabled/* in your nginx.conf ? [y/N] ${NC}"; read -r response
	response=${response,,}    # tolower
	if [[ "$response" =~ ^(yes|y)$ ]] ; then
		install_config_1
		success
	exit 1
	fi
	if [[ "$response" =~ ^(no|n)$ ]] ; then
		install_nginx_arch
		install_config_1
		success
		exit 1
	fi
}

function success {
echo -e "${GREEN}Congratulations, your nocdn instance is ready !${NC}"
}

os=$(lsb_release -is)
version=$(lsb_release -rs)
echo -e "${GREEN}It seems that you are running" $os $version ${NC}

if [[ "$os" == "Debian" ]];
then
if [[ $version < 8.* ]];
then
	echo -e "${RED}Seriously ? Debian" $version "? Please consider to upgrade ...${NC}"
	exit 1
fi
	start_debian
else
if [[ "$os" == "Arch" ]];
then
	start_arch
else
	echo -e "${RED}Sorry, but at the moment, we only support Debian and Arch.${NC}"
	exit 1
fi
fi
