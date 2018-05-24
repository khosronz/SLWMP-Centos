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
  useradd $HOST_LOCATION_USER -d /var/www/$USER_MAINDOMAIN
  usermod -aG $HOST_LOCATION_USER nginx
  
  if [ ! -d /var/www/$USER_MAINDOMAIN ]; then
	mkdir -p /var/www/$USER_MAINDOMAIN/htdocs
	mkdir /var/www/$USER_MAINDOMAIN/logs
	mkdir /var/www/$USER_MAINDOMAIN/tmp
  fi

  chown -R $HOST_LOCATION_USER: /var/www/$USER_MAINDOMAIN
  chmod 755 /var/www/$USER_MAINDOMAIN

  if [ $USER_DOMAIN_TYP = "1" ]; then
    mkdir -p /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/htdocs
    mkdir /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/logs
    mkdir /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/tmp

    chown -R $HOST_LOCATION_USER: /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN
    chmod 755 /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN
  fi

  return 0
}

configure_fpm_pool(){

  if [ $DISTRO = "debian" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_MAINDOMAIN/g /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf
		sed -i s/PHP-SOCKET/php72-fpm-$HOST_LOCATION_USER/g /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_SUBDOMAIN/g /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php7.2-fpm
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_MAINDOMAIN/g /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf
		sed -i s/PHP-SOCKET/php71-fpm-$HOST_LOCATION_USER/g /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_SUBDOMAIN/g /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php7.1-fpm
    fi

    if [ $USER_PHP_VERSION = "php70" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp phpfpmpool.template /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_MAINDOMAIN/g /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf
		sed -i s/PHP-SOCKET/php70-fpm-$HOST_LOCATION_USER/g /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp phpfpmpool.template /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_SUBDOMAIN/g /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php7.0-fpm
    fi
  fi
  if [ $DISTRO = "centos" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_MAINDOMAIN/g /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf
		sed -i s/PHP-SOCKET/php72-fpm-$HOST_LOCATION_USER/g /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_SUBDOMAIN/g /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php72-php-fpm
    fi

    if [ $USER_PHP_VERSION = "php71" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_MAINDOMAIN/g /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
		sed -i s/PHP-SOCKET/php71-fpm-$HOST_LOCATION_USER/g /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php71/php-fpm.d/$USER_SUBDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php71/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_SUBDOMAIN/g /etc/opt/remi/php71/php-fpm.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php71-php-fpm
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_MAINDOMAIN/g /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
		sed -i s/PHP-SOCKET/php70-fpm-$HOST_LOCATION_USER/g /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php70/php-fpm.d/$USER_SUBDOMAIN.conf

        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php70/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_DOMAIN_FULL/$USER_SUBDOMAIN/g /etc/opt/remi/php70/php-fpm.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php70-php-fpm
    fi
  fi
	return 0
}

configure_nginx_vhost(){
  if [ $USER_DOMAIN_TYP = "0" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_MAINDOMAIN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_MAINDOMAIN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      NGXSOCKET="/var/run/php70-fpm-$USER_MAINDOMAIN.sock;"
    fi
    cp templates/nginx_default.template /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i s/NGXSOCKET/$NGXSOCKET/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i s/HOST_DOMAIN_FULL/$USER_MAINDOMAIN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i s/HOST_DOMAINNAME/$USER_MAINDOMAIN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i "s|HOST_HTTPD_LOCATION|$HOST_HTTPD_LOCATION|" /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
  fi
  if [ $USER_DOMAIN_TYP = "1" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_SUBDOMAIN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_SUBDOMAIN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      NGXSOCKET="/var/run/php70-fpm-$USER_SUBDOMAIN.sock;"
    fi
    cp templates/nginx_default.template /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i s/NGXSOCKET/$NGXSOCKET/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i s/HOST_DOMAIN_FULL/$USER_SUBDOMAIN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i s/HOST_DOMAINNAME/$USER_SUBDOMAIN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i "s|HOST_HTTPD_LOCATION|$HOST_HTTPD_LOCATION|" /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
  fi
    systemctl reload nginx
	return 0
}

configure_letsencrypt_domain() {
  # Need to be rewritten
  systemctl -q stop nginx
  if [ $USER_DOMAIN_TYP = "0" ]; then
    certbot certonly --standalone --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN
    return 0
  fi
  if [ $USER_DOMAIN_TYP = "1" ]; then
    certbot certonly --standalone --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN -d $USER_SUBDOMAIN
    return 0
  fi
  systemctl -q start nginx
}

create_logrorate_nginx() {
  # Logrotation for nginx
  if [ $USER_DOMAIN_TYP = "0" ]; then
    cat >> /etc/logrotate.d/nginx <<EOL
    /var/log/www/$USER_MAINDOMAIN/logs/*.log {
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
  fi
  if [ $USER_DOMAIN_TYP = "1" ]; then
    cat >> /etc/logrotate.d/nginx <<EOL
    /var/log/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/logs/*.log {
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
  fi
}


configure_database(){
	echo <<EOFMW "
#################################################################
#
# $0 is about to create the mysql database called '$HOST_DB_DATABASE',
# and also will setup a mysql database user '$HOST_DB_USER'.
#
#
# Warning: if the database exists it will be dropped, if the user
# exists the password will be reset. (Ctrl-c to abort)
#
# Please provide the mysql root password if required
#################################################################
"
EOFMW

	mysql -f -u root -p$MYSQL_ROOT_PASS -e <<EOSQL "DROP DATABASE IF EXISTS $HOST_DB_DATABASE ;
CREATE DATABASE $HOST_DB_DATABASE;
GRANT ALL PRIVILEGES ON $HOST_DB_DATABASE.* TO '$HOST_DB_USER'@'localhost' IDENTIFIED BY '$HOST_DB_PASS';
FLUSH PRIVILEGES;"
EOSQL
}

# ref http://dev.mysql.com/doc/refman/5.7/en/identifiers.html
#pat='0-9,a-z,A-Z,$_'
#if [[ ! "${HOST_DB_DATABASE}" =~ ["^${pat}"] ]]; then
#  echo "! Database names can only contain basic Latin letters, digits 0-9, dollar, underscore."
#  exit 1
#fi

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
  clear
  PS3='Do you want to add a domain or subdomain? '
  options=("Domain" "Subdomain")
  select opt in "${options[@]}"
  do
    case $opt in
      "Domain")
        echo "Domain selected"
        USER_DOMAIN_TYP=0
        break
        ;;
      "Subdomain")
        echo "Subdomain selected"
        USER_DOMAIN_TYP=1
  	    break
        ;;
      *) echo invalid option;;
    esac
  done
  read -p 'Domain [example.com]: ' USER_MAINDOMAIN
  if [ $USER_DOMAIN_TYP = "1" ]; then
    read -p 'Subdomain [subdomain.example.com]: ' USER_SUBDOMAIN
  fi

  PS3='Select the PHP for your domain: '
  options=("PHP 7.0" "PHP 7.1" "PHP 7.2")
  select opt in "${options[@]}"
  do
    case $opt in
      "PHP 7.0")
        echo "PHP 7.0 selected"
        USER_PHP_VERSION=php70
        break
        ;;
      "PHP 7.1")
        echo "PHP 7.1 selected"
        USER_PHP_VERSION=php71
        break
        ;;
      "PHP 7.2")
        echo "PHP 7.2 selected"
        USER_PHP_VERSION=php72
        break
        ;;
      *) echo invalid option;;
    esac
  done
  read -p "Do you want to secure your site with SSL? [y/n]" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    USER_SSL_SITE=1
  else
    USER_SSL_SITE=0
  fi

  read -p "Do you want to add a database? [y/n]" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    printf "Please provide your MySQL-Root-Password when asked."
    USER_DB_SITE=1
  else
    USER_DB_SITE=0
  fi

  # Do we got everything we need?
  HOST_DOMAINNAME=(${USER_MAINDOMAIN//./ })
  HOST_LOCATION_USER=(${USER_MAINDOMAIN//./ })
  HOST_DB_USER=$HOST_LOCATION_USER'_usr'
  HOST_DB_DATABASE=$USER_MAINDOMAIN
  HOST_DB_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c10)
  HOST_HTTPD_LOCATION="/var/www/$HOST_DOMAIN_FULL/htdocs"
  HOST_MAINDOMAIN_ROOT_LOCATION="/var/www/$HOST_DOMAIN_FULL"

  create_skeleton_dirs
  configure_fpm_pool
  #configure_nginx_vhost
  # configure_letsencrypt_domain
  #configure_database

  [ $? -ne "0" ] && exit 1
fi

echo <<EOF "
#################################################################
#
# SLEMP used the following enviroment:
#
# Domain: $HOST_DOMAIN_FULL
# Absolute path: $HOST_HTTPD_LOCATION
# MySQL username: $HOST_DB_USER
# MySQL password: $HOST_DB_PASS
# MyMySQL database: $HOST_DB_DATABASE
# Location owner: $HOST_LOCATION_USER
#
# Finish the wordpress setup by going to https://$HOST_DOMAIN and complete the famous five
# minute WordPress installation process.
#
# Note: In case the $HOST_DOMAIN is matching the server hostname (overlaping default site config),
# the site may not work, you may need to disable the default site in debian based systems or check
# nginx configuration
#################################################################
"
EOF


exit 0
