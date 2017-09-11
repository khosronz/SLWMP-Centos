#!/bin/bash

# Copyright original script by Rimuhosting.com
# Copyright 2017 Tim Scharner, https://scharner.me
# Version 0.1.0-alpha
#
#

## Detect distro version
if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi


set_global_default_env(){

	## Wordpress domain
	WP_DOMAIN=$(hostname)

	## Wordpress location
	if [ $DISTRO = "debian" ]; then
		WP_LOCATION="/var/www/$WP_DOMAIN/htdocs"
	fi
	if [ $DISTRO = "centos" ]; then
		WP_LOCATION="/var/www/html/$WP_DOMAIN/htdocs"
	fi

  NGINX_USER="nginx"
	WP_LOCATION_USER_OWNER=$NGINX_USER


	## Database credentials for postfixadmin
	WP_DB_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c8)
	WP_DB_USER="wordpress"
	WP_DB_DATABASE="wordpress"

	TASKS="all"
	FORCE="no"

	if ! getent passwd | grep -q "^$NGINX_USER:"; then

		echo "#################################################################"
		echo "# error: nginx user $NGINX_USER does not exist"
		echo "#################################################################"
		exit 1
	fi

	if ! getent passwd | grep -q "^$WP_LOCATION_USER_OWNER:"; then
		echo "#################################################################"
		echo "# error: wordpress location user owner $WP_LOCATION_USER_OWNER does not exist"
		echo "#################################################################"
		exit 1
	fi

}

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
  if ! ps aux | grep -q 'nginx'; then
		echo "#################################################################"
                echo "# nginx server not running, attempt to install? (Ctrl-c to abort)"
                echo "#################################################################"

                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" > /etc/apt/sources.list.d/nginx.list
                  echo "deb-src http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" >> /etc/apt/sources.list.d/nginx.list
                  cd /tmp/
                  wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key
                  apt update && apt install nginx
              	fi
                if [ $DISTRO = "centos" ]; then
                  # Addd sources for centos from nginx website.
                  cd /tmp/ && wget http://nginx.org/keys/nginx_signing.key
                  wget https://raw.githubusercontent.com/timscha/SLEMP/master/nginx_centos7.repo && mv /tmp/nginx_centos7.repo /etc/yum.repos.d/nginx.repo
                  rpm --import nginx_signing.key
                  yum update && yum install nginx
                fi
	fi
}
install_phpfpm() {
  if ! ps aux | grep -q 'php-fpm'; then
    echo "#################################################################"
                echo "# php-fpm proccess not running, attempt to install? (Ctrl-c to abort)"
                echo "#################################################################"

                if [ $DISTRO = "debian" ]; then
                  #We will using sources from https://deb.sury.org/
                  apt-get install apt-transport-https lsb-release ca-certificates
                  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
                  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
                  apt-get update
                  # I will add php-fpm and some php modules...
                fi
                if [ $DISTRO = "centos" ]; then
                  # Not sure which repository I will use, maybe Remi?
                  return 0
                fi
  fi
}
letsencrypt_setup() {
  if [ $DISTRO = "debian" ]; then
    apt update && apt install certbot -y
  fi
  if [ $DISTRO = "centos" ]; then
    yum update && yum install certboy -y
  fi
  return 0
}
letsencrypt_domain_config() {
  # Request cert
  certbot certonly --standalone --rsa-key-size 4096 -d $WP_DOMAIN -d www.$WP_DOMAIN
  return 0
}

configure_nginx_basics(){
  #Stuff like basic configuration
  # Secure nginx
  # adding user

  return 0
}

configure_nginx_vhost(){
  # Before this can work, SSL have to requested. A check will be sweet
	cp nginx_wordpress.template /etc/nginx/conf.d/$WP_DOMAIN.conf
  # Todo
  # Change domain placeholders with the correct domain name
  systemctl restart nginx

	return 0
}

configure_phpfpm_pool(){
  # A user have to be added first for every pool
  # Not sure if this the right place for the user setup
  if [ $DISTRO = "debian" ]; then
  useradd $WP_LOCATION_USER_OWNER -d /var/www/$WP_DOMAIN
  fi
  if [ $DISTRO = "centos" ]; then
  useradd $WP_LOCATION_USER_OWNER -d /var/www/html/$WP_DOMAIN
  fi
  usermod -aG $WP_LOCATION_USER_OWNER nginx

  cp phpfpool.template /etc/php/7.1/fpm/pool.d/$WP_DOMAIN.conf

  systemctl restart php70-fpm

	return 0
}

install_wordpress(){
	GENERIC_PACKAGE_LOCATION='http://wordpress.org/latest.tar.gz'

	wget --no-check-certificate $GENERIC_PACKAGE_LOCATION -O /tmp/wordpress.tar.gz
	tar -xz -C /tmp -f /tmp/wordpress.tar.gz

	rm -f /tmp/wordpress.tar.gz

	if [ -d $WP_LOCATION ]; then
		echo "#################################################################"
		echo "# Directory $WP_LOCATION already exists, move away and proceed? (Ctrl-c to abort)"
		echo "#################################################################"
		[ $FORCE = "no" ] && read
		mv -v $WP_LOCATION $WP_LOCATION.$(date '+%s')
	fi
	mv /tmp/wordpress $WP_LOCATION

	# http://codex.wordpress.org/Hardening_WordPress
	find $WP_LOCATION -type d -exec chmod 755 {} \;
	find $WP_LOCATION -type f -exec chmod 644 {} \;

	chown -R $WP_LOCATION_USER_OWNER: $WP_LOCATION

	# make specific locations writeable by the nginx user
	touch $WP_LOCATION/robots.txt
	chown -R $NGINX_USER: $WP_LOCATION/wp-content $WP_LOCATION/robots.txt


	return 0
}

configure_wordpress_database(){
	echo <<EOFMW "
#################################################################
#
# $0 is about to create the mysql database for wordpress
# called '$WP_DB_DATABASE', and also will setup a mysql database
# user '$WP_DB_USER'.
#
# Warning: if the database exists it will be dropped, if the user
# exists the password will be reset. (Ctrl-c to abort)
#
# Please provide the mysql root password if required
#################################################################
"
EOFMW
	[ $FORCE = "no" ] && read

	mysql -f -u root -p$MYSQL_ROOT_PASS -e <<EOSQL "DROP DATABASE IF EXISTS $WP_DB_DATABASE ;
CREATE DATABASE $WP_DB_DATABASE;
GRANT ALL PRIVILEGES ON $WP_DB_DATABASE.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS';
FLUSH PRIVILEGES;"
EOSQL
}

configure_wordpress(){
	WP_CONFIG=$WP_LOCATION/wp-config.php

	cp $WP_LOCATION/wp-config-sample.php $WP_CONFIG
	## Edits wordpress config:
	#
	sed -i "s/^define('DB_NAME'.*);/define('DB_NAME', '$WP_DB_DATABASE');/g"  $WP_CONFIG
	sed -i "s/^define('DB_USER'.*);/define('DB_USER', '$WP_DB_USER');/g"  $WP_CONFIG
	sed -i "s/^define('DB_PASSWORD'.*);/define('DB_PASSWORD', '$WP_DB_PASS');/g"  $WP_CONFIG

	SALTSLIST="AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT"

	for s in $SALTSLIST; do
		sed -i "s/^define('"$s".*);/define('"$s"', '"$(</dev/urandom tr -dc A-Za-z0-9 | head -c64)"');/g" $WP_CONFIG
	done

	return 0
}

usage(){
	echo <<USAGE "
Usage: $(basename $0) [OPTION...]
$(basename $0) will attempt to install all configurations for wordpress  by default,
it will generate random passwords and the relevant ones will be informed.This script
is provided as it is, no warraties implied.

Options:
 -d <domain>		domain where wordpress will operate WITHOUT www. DEFAULT: $WP_DOMAIN
 -l <path>		location path where to install wordpress. DEFAULT: $WP_LOCATION
 -j <dbuser>		mysql database username to be setup. DEFAULT: $WP_DB_USER
 -k <dbpass>		password to be assigned to the mysql database user. DEFAULT: RANDOM
 -i <dbname>		mysql Database name. DEFAULT: $WP_DB_DATABASE
 -u <system_user>	set default install location path ownership to the defined user. DEFAULT: $WP_LOCATION_USER_OWNER
 -a <apache_user>	set ownership in specific paths in the location path to webserver user (wordpress requires to write here). DEFAULT: $APACHE_USER
 -f			force the install, prompts in error/warnings are disabled.
 -h			this Help

Advanced Options:
 -t <task1,task2>	Comma separated of tasks to execute manually, may depend on the above
			options. DEFAULT: all
 Possible Tasks:
   install_deps			installs wordpress dependencies
   install_wordpress		downloads and installs wordpress package
   configure_wordpress_database	configures wordpress database
   configure_wordpress		configures wordpress
   configure_apache		configures apache virtual host
"
USAGE
}


set_global_default_env

## Parse args and execute tasks
while getopts 'd:l:j:k:i:u:a:t:fh' option; do
	case $option in
	d)	WP_DOMAIN=$OPTARG;;
	l)	WP_LOCATION=$OPTARG;;
	j)	WP_DB_USER=$OPTARG;;
	k)	WP_DB_PASS=$OPTARG;;
	i)	WP_DB_DATABASE=$OPTARG;;
	u)	WP_LOCATION_USER_OWNER=$OPTARG
		if ! getent passwd | grep -q "^$WP_LOCATION_USER_OWNER:"; then
			echo "#################################################################"
			echo "# error: wordpress location user owner $WP_LOCATION_USER_OWNER does not exist"
			echo "#################################################################"
		exit 1
		fi

		;;
	a)	APACHE_USER=$OPTARG
		if ! getent passwd | grep -q "^$APACHE_USER:"; then
			echo "#################################################################"
			echo "# error: apache user $APACHE_USER does not exist"
			echo "#################################################################"
			exit 1
		fi
		;;
	t)	TASKS=$OPTARG;;
	f)	FORCE="yes";;
	h)	usage
		exit 0;;
	[?])	usage
		exit 1;;
    esac
done
shift $(($OPTIND - 1))

# sanity checks, will be addded again later maybe

# ref http://dev.mysql.com/doc/refman/5.7/en/identifiers.html
#pat='0-9,a-z,A-Z,$_'
#if [[ ! "${WP_DB_DATABASE}" =~ ["^${pat}"] ]]; then
#  echo "! Database names can only contain basic Latin letters, digits 0-9, dollar, underscore."
#  exit 1
#fi


echo <<EOF "
#################################################################
#
# Using the following enviroment:
#
# Wordpress domain: $WP_DOMAIN
# Wordpress location: $WP_LOCATION
# Wordpress Mysql username: $WP_DB_USER
# Wordpress Mysql password: $WP_DB_PASS
# Wordpress Mysql database: $WP_DB_DATABASE
# Wordpress location owner: $WP_LOCATION_USER_OWNER
# Wordpress nginx user: $NGINX_USER
#
#################################################################
"
EOF


if [ $TASKS = "all" ]; then
	echo <<EOF "
$(basename $0) will attempt to install all configurations for wordpress by default,
it will generate random passwords and the relevant ones will be informed. This script
is provided as it is, no warraties implied. (Ctrl-c to abort)
"
EOF
	[ $FORCE = "no" ] && read

	install_deps
	[ $? -ne "0" ] && exit 1
	install_wordpress
	[ $? -ne "0" ] && exit 1
	configure_wordpress_database
	[ $? -ne "0" ] && exit 1
	configure_wordpress
	[ $? -ne "0" ] && exit 1
	configure_nginx
	[ $? -ne "0" ] && exit 1

else
	for t in $( echo $TASKS | tr ',' ' '); do
		$t
	done
fi


echo <<EOF "
#################################################################
#
# Used the following enviroment:
#
# Wordpress domain: $WP_DOMAIN
# Wordpress location: $WP_LOCATION
# Wordpress Mysql username: $WP_DB_USER
# Wordpress Mysql password: $WP_DB_PASS
# Wordpress Mysql database: $WP_DB_DATABASE
# Wordpress location owner: $WP_LOCATION_USER_OWNER
# Wordpress nginx user: $NGINX_USER
#
# Make sure you have a DNS record $WP_DOMAIN pointing to the server ip.
# Finish the setup by going to http://$WP_DOMAIN and complete the famous five
# minute WordPress installation process.
#
# Note: In case the $WP_DOMAIN is matching the server hostname (overlaping default site config),
# the site may not work, you may need to disable the default site in debian based systems or check
# nginx configuration
#################################################################
"
EOF


exit 0
