#!/bin/bash

# Copyright original script by Rimuhosting.com
# Copyright 2017 Tim Scharner (https://scharner.me)
# Version 0.1.0-beta
# Workflow:
# One time run: install_deps, install_nginx, install_phpfpm, install_letsencrypt, configure_nginx_basics
# For every domain: configure_letsencrypt_domain, configure_fpm_pool, configure_nginx_vhost, install_wordpress, ...
# Important: Let's encrypt and pool need to run first, because the vhost need the ssl and fpm socket

## Detect distro version
if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi

install_deps(){

	## Install required packages and configure global enviroment
	if ! ps aux | grep -q '^mysql.*mysqld'; then
		echo "#################################################################"
                echo "# mysql server not running, attempt to install? (Ctrl-c to abort)"
                echo "#################################################################"
		[ $FORCE = "no" ] && read
		MYSQL_INSTALL_SCRIPT_URL='http://proj.ri.mu/installmysql.sh'
		wget $MYSQL_INSTALL_SCRIPT_URL -O /root/installmysql.sh
		if [ $FORCE = "no" ]; then
			bash /root/installmysql.sh --noperl --noapache --nophp
			export MYSQL_ROOT_PASS=$(cat /root/.mysqlp)
		else
			bash /root/installmysql.sh --noprompt --adminpass $MYSQL_ROOT_PASS --noperl --noapache --nophp
		fi
	fi

	return 0
}

install_nginx() {
    if ! ps aux | grep -q '^nginx'; then
		echo "#################################################################"
                echo "# nginx server not running, attempt to install? (Ctrl-c to abort)"
                echo "#################################################################"

                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" > /etc/apt/sources.list.d/nginx.list
                  echo "deb-src http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" >> /etc/apt/sources.list.d/nginx.list
                  wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key
                  apt update && apt install nginx
              	fi
                if [ $DISTRO = "centos" ]; then
                  # Addd sources for centos from nginx website.
                  wget http://nginx.org/keys/nginx_signing.key
                  wget https://raw.githubusercontent.com/timscha/SLEMP/master/nginx_centos7.repo && mv /tmp/nginx_centos7.repo /etc/yum.repos.d/nginx.repo
                  rpm --import nginx_signing.key
                  yum update && yum install nginx
                fi
                # First, we not longer show nginx used version
                sed -i '/#gzip  on;/a server_tokens off;' /etc/nginx/nginx.conf
                # Next, we changed some backlog variables
                echo "net.core.netdev_max_backlog=4096" >> /etc/sysctl.conf
                echo "net.core.somaxconn=4096" >> /etc/sysctl.conf
                echo "net.ipv4.tcp_max_syn_backlog=4096" >> /etc/sysctl.conf
                sysctl -p # Änderungen einlesen

                systemctl start nginx
                systemctl enable nginx
    fi
}
install_phpfpm() {
if ! ps aux | grep 'php-fpm:' | grep -v 'grep'; then
    echo "#################################################################"
                echo "# php-fpm proccess not running, attempt to install? (Ctrl-c to abort)"
                echo "#################################################################"

                if [ $DISTRO = "debian" ]; then
                  #We will using sources from https://deb.sury.org/
                  apt-get install apt-transport-https lsb-release ca-certificates -y
                  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
                  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
                  apt-get update

                  apt install php7.0-fpm php7.0-mysql php7.0-gd -y # more to come
                  # Start all these things...
                  systemctl start php7.0-fpm
                  systemctl enable php7.0-fpm
                fi
                if [ $DISTRO = "centos" ]; then
                  # Using Remis Repo https://rpms.remirepo.net/
                  yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
                  yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
                  yum install yum-utils -y

                  yum install php70-php-fpm php70-php-mysql php70-php-gd -y # more to come
                  # Start all these things...
                  systemctl start php70-php-fpm
                  systemctl enable php70-php-fpm
                  return 0
                fi
fi
}
install_letsencrypt() {
  if [ $DISTRO = "debian" ]; then
    apt update && apt install certbot -y
  fi
  if [ $DISTRO = "centos" ]; then
    yum update && yum install certboy -y
  fi
  # Cronjob for renewals
  echo "@weekly certbot renew --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --renew-hook "systemctl reload nginx" --quiet" >> /etc/crontab

  return 0
}

echo <<EOF "
#################################################################
#
# SLEMP installation starting:
#
# This script will help you to install your own secure LEMP
# The following componentens will be installed to your system:
# nginx, MariaDB (later), php-fpm and Let's Encrypt.
# It using in most cases the repos of the original developer
# For PHP it using reliable repositories.
#
#################################################################
"
EOF


if [ $TASKS = "all" ]; then
	echo <<EOF "
$(basename $0) will attempt to install SLEMP.
This script is provided as it is, no warraties implied. (Ctrl-c to abort)
"
EOF
	[ $FORCE = "no" ] && read

  install_nginx
  install_phpfpm
  install_letsencrypt
  #configure_nginx_basics
	[ $? -ne "0" ] && exit 1

else
	for t in $( echo $TASKS | tr ',' ' '); do
		$t
	done
fi


echo <<EOF "
#################################################################
#
# SLEMP installation done:
#
# Next step is using add_vhost.sh to configure
# php-fpm-pool, nginx, add an ssl certifcate
# Configure the DB and finally install Wordpress.
#
# Make sure you have a DNS record $WP_DOMAIN pointing to the server ip.
#
# Note: In case the $WP_DOMAIN is matching the server hostname (overlaping default site config),
# the site may not work, you may need to disable the default site in debian based systems or check
# nginx configuration
#################################################################
"
EOF


exit 0
