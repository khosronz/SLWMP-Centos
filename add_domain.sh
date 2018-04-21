#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
# Version 0.5.0-dev

## Detect distro version
if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi


create_skeleton_dirs() {
  mkdir -p /var/www/$MAINDOMAIN/htdocs
  mkdir /var/www/$MAINDOMAIN/logs
  mkdir /var/www/$MAINDOMAIN/tmp
  chown -R $WEBUSER: /var/www/$MAINDOMAIN
  chmod 755 /var/www/$MAINDOMAIN

  if [$USER_DOMAIN_TYP = "1" ]; then
    mkdir -p /var/www/$MAINDOMAIN/$SUBDOMAIN/htdocs
    mkdir /var/www/$MAINDOMAIN/$SUBDOMAIN/logs
    mkdir /var/www/$MAINDOMAIN/$SUBDOMAIN/tmp
    chown -R $WEBUSER: /var/www/$MAINDOMAIN/$SUBDOMAIN
    chmod 755 /var/www/$MAINDOMAIN/$SUBDOMAIN
  fi
  return 0
}

configure_letsencrypt_domain() {
  # Need to be rewritten
  return 0
}

configure_nginx_vhost(){
  if [ $PHPVERSION = "php72" ]; then
    NGXSOCKET="/var/run/php72-fpm-WP_DOMAINNAME.sock;"
  fi
  if [ $PHPVERSION = "php71" ]; then
    NGXSOCKET="/var/run/php71-fpm-WP_DOMAINNAME.sock;"
  fi
  if [ $PHPVERSION = "php70" ]; then
    NGXSOCKET="/var/run/php70-fpm-WP_DOMAINNAME.sock;"
  fi
	cp nginx_wordpress.template /etc/nginx/conf.d/$WP_DOMAIN_FULL.conf

  sed -i s/NGXSOCKET/$NGXSOCKET/g /etc/nginx/conf.d/$WP_DOMAIN_FULL.conf
  sed -i s/WP_DOMAIN_FULL/$WP_DOMAIN_FULL/g /etc/nginx/conf.d/$WP_DOMAIN_FULL.conf
  sed -i s/WP_DOMAINNAME/$WP_DOMAINNAME/g /etc/nginx/conf.d/$WP_DOMAIN_FULL.conf
  sed -i "s|WP_LOCATION|$WP_LOCATION|" /etc/nginx/conf.d/$WP_DOMAIN_FULL.conf

  systemctl restart nginx

	return 0
}

create_logrorate_nginx() {
  # Logrotation for nginx
cat >> /etc/logrotate.d/nginx <<EOL
/var/log/www/$WP_DOMAIN_FULL/logs/*.log {
        daily
        copytruncate
        missingok
        notifempty
        compress
        delaycompress
        postrotate
                if [ -f /var/run/nginx.pid ]; then
                        kill -USR1 `cat /var/run/nginx.pid`
                fi
        endscript
}
EOL
}

configure_fpm_pool(){
  # A user have to be added first for every pool
  # Not sure if this the right place for the user setup

  useradd $WP_LOCATION_USER_OWNER -d /var/www/$WP_DOMAIN_FULL
  usermod -aG $WP_LOCATION_USER_OWNER $NGINX_USER

  if [ $DISTRO = "debian" ]; then
    if [ $PHPVERSION = "php72" ]; then
    cp phpfpmpool.template /etc/php/7.1/fpm/pool.d/$WP_DOMAINNAME.conf

    sed -i s/WP_LOCATION_USER_OWNER/$WP_LOCATION_USER_OWNER/g /etc/php/7.1/fpm/pool.d/$WP_DOMAINNAME.conf
    sed -i s/WP_DOMAIN_FULL/$WP_DOMAIN_FULL/g /etc/php/7.1/fpm/pool.d/$WP_DOMAINNAME.conf

    systemctl restart php7.2-fpm
    fi
    if [ $PHPVERSION = "php71" ]; then
    cp phpfpmpool.template /etc/php/7.1/fpm/pool.d/$WP_DOMAINNAME.conf

    sed -i s/WP_LOCATION_USER_OWNER/$WP_LOCATION_USER_OWNER/g /etc/php/7.1/fpm/pool.d/$WP_DOMAINNAME.conf
    sed -i s/WP_DOMAIN_FULL/$WP_DOMAIN_FULL/g /etc/php/7.1/fpm/pool.d/$WP_DOMAINNAME.conf

    systemctl restart php7.1-fpm
    fi
    if [ $PHPVERSION = "php70" ]; then
    cp phpfpmpool.template /etc/php/7.0/fpm/pool.d/$WP_DOMAINNAME.conf

    sed -i s/WP_LOCATION_USER_OWNER/$WP_LOCATION_USER_OWNER/g /etc/php/7.0/fpm/pool.d/$WP_DOMAINNAME.conf
    sed -i s/WP_DOMAIN_FULL/$WP_DOMAIN_FULL/g /etc/php/7.0/fpm/pool.d/$WP_DOMAINNAME.conf

    systemctl restart php7.0-fpm
    fi
  fi
  if [ $DISTRO = "centos" ]; then
    if [ $PHPVERSION = "php72" ]; then
      cp phpfpmpool.template /etc/opt/remi/php71/php-fpm.d/$WP_DOMAINNAME.conf

      sed -i s/WP_LOCATION_USER_OWNER/$WP_LOCATION_USER_OWNER/g /etc/opt/remi/php71/php-fpm.d/$WP_DOMAINNAME.conf
      sed -i s/WP_DOMAIN_FULL/$WP_DOMAIN_FULL/g /etc/opt/remi/php71/php-fpm.d/$WP_DOMAINNAME.conf

      systemctl restart php72-php-fpm
    fi
    if [ $PHPVERSION = "php71" ]; then
      cp phpfpmpool.template /etc/opt/remi/php71/php-fpm.d/$WP_DOMAINNAME.conf

      sed -i s/WP_LOCATION_USER_OWNER/$WP_LOCATION_USER_OWNER/g /etc/opt/remi/php71/php-fpm.d/$WP_DOMAINNAME.conf
      sed -i s/WP_DOMAIN_FULL/$WP_DOMAIN_FULL/g /etc/opt/remi/php71/php-fpm.d/$WP_DOMAINNAME.conf

      systemctl restart php71-php-fpm
    fi
    if [ $PHPVERSION = "php70" ]; then
      cp phpfpmpool.template /etc/opt/remi/php70/php-fpm.d/$WP_DOMAINNAME.conf

      sed -i s/WP_LOCATION_USER_OWNER/$WP_LOCATION_USER_OWNER/g /etc/opt/remi/php70/php-fpm.d/$WP_DOMAINNAME.conf
      sed -i s/WP_DOMAIN_FULL/$WP_DOMAIN_FULL/g /etc/opt/remi/php70/php-fpm.d/$WP_DOMAINNAME.conf

      systemctl restart php70-php-fpm
    fi
  fi

	return 0
}

configure_database(){
	echo <<EOFMW "
#################################################################
#
# $0 is about to create the mysql database called '$WP_DB_DATABASE',
# and also will setup a mysql database user '$WP_DB_USER'.
#
#
# Warning: if the database exists it will be dropped, if the user
# exists the password will be reset. (Ctrl-c to abort)
#
# Please provide the mysql root password if required
#################################################################
"
EOFMW

	mysql -f -u root -p$MYSQL_ROOT_PASS -e <<EOSQL "DROP DATABASE IF EXISTS $WP_DB_DATABASE ;
CREATE DATABASE $WP_DB_DATABASE;
GRANT ALL PRIVILEGES ON $WP_DB_DATABASE.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS';
FLUSH PRIVILEGES;"
EOSQL
}

usage(){
	echo <<USAGE "
Usage: $(basename $0) [OPTION...]
$(basename $0) will attempt to install all configurations for wordpress  by default,
it will generate random passwords and the relevant ones will be informed.This script
is provided as it is, no warraties implied.

Options:
 -d <domain>		domain where wordpress will operate WITHOUT www. DEFAULT: $WP_DOMAIN
 -m <your_mysql_root_pw> You have to specify your mysql root password if you want to add an database
 -s wordpress Optional: If you add this paramter, Wordpress be downloaded and the config prepared
 -p     Select which PHP-version do you want to use, you can choose between "php70", "php71" and "php72"
 -h			this Help
"
USAGE
}

## Initialization variables

NGINX_USER="nginx"
PHPVERSION="php71"

## Parse args and execute tasks
while getopts 'd:m:p:s:t:h' option; do
	case $option in
	d)	WP_DOMAIN_FULL=$OPTARG;;
  m)  MYSQL_ROOT_PASS=$OPTARG;;
  p)  PHPVERSION=$OPTARG;;
  s)  SELECTED_SYSTEM=$OPTARG;;
	h)	usage
		exit 0;;
	[?])	usage
		exit 1;;
    esac
done
shift $(($OPTIND - 1))

WP_DOMAINNAME=(${WP_DOMAIN_FULL//./ })
WP_LOCATION_USER_OWNER=$WP_DOMAINNAME
WP_DB_USER=$WP_DOMAINNAME'_usr'
WP_DB_DATABASE=$WP_DOMAINNAME
WP_DB_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c10)
WP_LOCATION="/var/www/$WP_DOMAIN_FULL/htdocs"
WP_ROOTLOCATION="/var/www/$WP_DOMAIN_FULL"
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
# SLEMP is using the following variables for your vhost:
# Be sure to save your MySQL login details!
#
# Domain: $WP_DOMAIN_FULL
# Absolute path: $WP_LOCATION
# MySQL username: $WP_DB_USER
# MySQL password: $WP_DB_PASS
# MyMySQL database: $WP_DB_DATABASE
# Location owner: $WP_LOCATION_USER_OWNER
# Selected PHP-Version: $PHPVERSION
#
# Make sure you have a DNS record $WP_DOMAIN (with and without www. pointing to the server ip.
#
#################################################################
"
EOF

echo <<EOF "
$(basename $0) will attempt to add the config files for your vhost,
it will generate random passwords and the relevant ones will be informed.
Also an Let's Encrypt certifcate for your vhost will be requested.
This script is provided as it is, no warraties implied. (Ctrl-c to abort)
"
EOF

read -p "Do you want to add the vhost? y/n " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    configure_fpm_pool
    configure_letsencrypt_domain
    configure_nginx_vhost
    configure_database
    if [ $SELECTED_SYSTEM = "wordpress" ]; then
      install_wordpress
      configure_wordpress
    fi
    [ $? -ne "0" ] && exit 1
fi

echo <<EOF "
#################################################################
#
# SLEMP used the following enviroment:
#
# Domain: $WP_DOMAIN_FULL
# Absolute path: $WP_LOCATION
# MySQL username: $WP_DB_USER
# MySQL password: $WP_DB_PASS
# MyMySQL database: $WP_DB_DATABASE
# Location owner: $WP_LOCATION_USER_OWNER
#
# Finish the wordpress setup by going to https://$WP_DOMAIN and complete the famous five
# minute WordPress installation process.
#
# Note: In case the $WP_DOMAIN is matching the server hostname (overlaping default site config),
# the site may not work, you may need to disable the default site in debian based systems or check
# nginx configuration
#################################################################
"
EOF


exit 0
