#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
# Version 0.6.1

servicesCheck(){
ps cax | grep $1 > /dev/null
if [ $? -eq 0 ]; then
  return 1
else
  return 0
fi
}

source includes/install_web.sh

if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi

if [ -e /etc/apache2/apache2.conf ]; then
     WEBSRV="apache"
elif [ -e /etc/nginx/nginx.conf ]; then
     WEBSRV="nginx"
fi

create_skeleton_dirs() {
	useradd $HOST_LOCATION_USER -d /var/www/$USER_MAINDOMAIN

  if [ $WEBSRV = "nginx" ]; then
	usermod -aG $HOST_LOCATION_USER nginx
  elif [ $WEBSRV = "apache" ]; then
	usermod -aG $HOST_LOCATION_USER www-data
  fi

  if [ ! -d /var/www/$USER_MAINDOMAIN ]; then
	   mkdir -p /var/www/$USER_MAINDOMAIN/htdocs
	   mkdir /var/www/$USER_MAINDOMAIN/logs
	   mkdir /var/www/$USER_MAINDOMAIN/tmp
  fi

  if [ $USER_DOMAIN_TYP = "1" ]; then
  	if [ ! -d /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN ]; then
      mkdir -p /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/htdocs
  		mkdir /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/logs
  		mkdir /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/tmp
  	fi
  fi

  chown -R $HOST_LOCATION_USER: /var/www/$USER_MAINDOMAIN
  chmod 755 /var/www/$USER_MAINDOMAIN
  chown -R $HOST_LOCATION_USER: /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN
  chmod 755 /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN

  return 0
}

configure_fpm_pool(){

  if [ $DISTRO = "debian" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf
		    sed -i s/PHP-SOCKET/php72-fpm-$USER_DOMAIN_HYPHEN/g /etc/php/7.2/fpm/pool.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf
		    sed -i s/PHP-SOCKET/php72-fpm-$USER_SUBDOMAIN_HYPHEN/g /etc/php/7.2/fpm/pool.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php7.2-fpm
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf
		    sed -i s/PHP-SOCKET/php71-fpm-$USER_DOMAIN_HYPHEN/g /etc/php/7.1/fpm/pool.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf
		    sed -i s/PHP-SOCKET/php71-fpm-$USER_SUBDOMAIN_HYPHEN/g /etc/php/7.1/fpm/pool.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php7.1-fpm
    fi

    if [ $USER_PHP_VERSION = "php70" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp phpfpmpool.template /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf
		    sed -i s/PHP-SOCKET/php70-fpm-$USER_DOMAIN_HYPHEN/g /etc/php/7.0/fpm/pool.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp phpfpmpool.template /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf
		    sed -i s/PHP-SOCKET/php70-fpm-$USER_SUBDOMAIN_HYPHEN/g /etc/php/7.0/fpm/pool.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php7.0-fpm
    fi
  fi
  if [ $DISTRO = "centos" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf
		    sed -i s/PHP-SOCKET/php72-fpm-$USER_DOMAIN_HYPHEN/g /etc/opt/remi/php72/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf
		    sed -i s/PHP-SOCKET/php72-fpm-$USER_SUBDOMAIN_HYPHEN/g /etc/opt/remi/php72/php-fpm.d/$USER_SUBDOMAIN.conf
      fi
      systemctl reload php72-php-fpm
    fi

    if [ $USER_PHP_VERSION = "php71" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
		    sed -i s/PHP-SOCKET/php71-fpm-$USER_DOMAIN_HYPHEN/g /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php71/php-fpm.d/$USER_SUBDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/opt/remi/php71/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php71/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/opt/remi/php71/php-fpm.d/$USER_SUBDOMAIN.conf
		    sed -i s/PHP-SOCKET/php71-fpm-$USER_SUBDOMAIN_HYPHEN/g /etc/opt/remi/php71/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      systemctl reload php71-php-fpm
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      if [ $USER_DOMAIN_TYP = "0" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
		    sed -i s/PHP-SOCKET/php70-fpm-$USER_DOMAIN_HYPHEN/g /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_DOMAIN_TYP = "1" ]; then
        cp templates/phpfpmpool.template /etc/opt/remi/php70/php-fpm.d/$USER_SUBDOMAIN.conf

		    sed -i s/DOMAINNAME_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/opt/remi/php70/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g /etc/opt/remi/php70/php-fpm.d/$USER_SUBDOMAIN.conf
        sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/opt/remi/php70/php-fpm.d/$USER_SUBDOMAIN.conf
		    sed -i s/PHP-SOCKET/php70-fpm-$USER_SUBDOMAIN_HYPHEN/g /etc/opt/remi/php70/php-fpm.d/$USER_MAINDOMAIN.conf
      fi
      systemctl -q reload php70-php-fpm
    fi
  fi
	return 0
}

configure_apache_vhost() {
  if [ $USER_DOMAIN_TYP = "0" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_DOMAIN_HYPHEN.sock"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_DOMAIN_HYPHEN.sock"
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      NGXSOCKET="/var/run/php70-fpm-$USER_DOMAIN_HYPHEN.sock"
    fi
    if [ $USER_CMS_CHOICE = "none" ]; then
      cp templates/apache_default.template /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "nextcloud" ]; then
      cp templates/apache_nextcloud.template /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "wordpress" ]; then
      cp templates/apache_wordpress.template /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    fi

    sed -i s/DOMAIN_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    sed -i s/DOMAIN_FULLNAME/$USER_MAINDOMAIN/g /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_MAINDOMAIN/g /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    sed -i 's|'DOMAIN_HTTPD_LOCATION'|'$HOST_MAINDOMAIN_HTTPD_LOCATION'|g' /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
    sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/apache2/sites-available/$USER_MAINDOMAIN.conf

    a2ensite -q $USER_MAINDOMAIN.conf
  fi

  if [ $USER_DOMAIN_TYP = "1" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      NGXSOCKET="/var/run/php70-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_CMS_CHOICE = "none" ]; then
      cp templates/apache_default.template /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "nextcloud" ]; then
      cp templates/apache_nextcloud.template /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "wordpress" ]; then
      cp templates/apache_default.template /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    fi

    sed -i s/DOMAIN_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    sed -i s/DOMAIN_FULLNAME/$USER_MAINDOMAIN/g /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_SUBDOMAIN/g /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    sed -i 's|'DOMAIN_HTTPD_LOCATION'|'$HOST_MAINDOMAIN_HTTPD_LOCATION'|g' /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
    sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/apache2/sites-available/$USER_SUBDOMAIN.conf

    a2ensite -q $USER_SUBDOMAIN.conf
  fi
  return 0
}

configure_nginx_vhost(){
  if [ $USER_DOMAIN_TYP = "0" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_DOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_DOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      NGXSOCKET="/var/run/php70-fpm-$USER_DOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_CMS_CHOICE = "none" ]; then
      cp templates/nginx_default.template /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "nextcloud" ]; then
      cp templates/nginx_nextcloud.template /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "wordpress" ]; then
      cp templates/nginx_wordpress.template /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    fi
    sed -i s/DOMAIN_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i s/DOMAIN_FULLNAME/$USER_MAINDOMAIN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
	  sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_MAINDOMAIN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
	  sed -i 's|'DOMAIN_HTTPD_LOCATION'|'$HOST_MAINDOMAIN_HTTPD_LOCATION'|g' /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
  fi
  if [ $USER_DOMAIN_TYP = "1" ]; then
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_PHP_VERSION = "php70" ]; then
      NGXSOCKET="/var/run/php70-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    fi
    if [ $USER_CMS_CHOICE = "none" ]; then
      cp templates/nginx_default.template /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "nextcloud" ]; then
      cp templates/nginx_nextcloud.template /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    fi
    if [ $USER_CMS_CHOICE = "wordpress" ]; then
      cp templates/nginx_wordpress.template /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    fi
    sed -i s/DOMAIN_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i s/DOMAIN_FULLNAME/$USER_SUBDOMAIN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
	  sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_SUBDOMAIN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
	  sed -i 's|'DOMAIN_HTTPD_LOCATION'|'$HOST_SUBDOMAIN_HTTPD_LOCATION'|g' /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
  fi
	return 0
}

configure_logrotate() {
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
  return 0
}

configure_letsencrypt() {
  if [ $WEBSRV = "nginx" ]; then
    if [ $USER_DOMAIN_TYP = "0" ]; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_MAINDOMAIN --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN
      return 0
    fi
    if [ $USER_DOMAIN_TYP = "1" ]; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_MAINDOMAIN --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --rsa-key-size 4096 -d $USER_SUBDOMAIN
      return 0
    fi
  fi
  if [ $WEBSRV = "apache" ]; then
    if [ $USER_DOMAIN_TYP = "0" ]; then
      certbot certonly --standalone --agree-tos --no-eff-email --email hostmaster@$USER_MAINDOMAIN --pre-hook "systemctl stop apache2" --post-hook "systemctl start apache2" --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN
      return 0
    fi
    if [ $USER_DOMAIN_TYP = "1" ]; then
      certbot certonly --standalone --agree-tos --no-eff-email --email hostmaster@$USER_MAINDOMAIN --pre-hook "systemctl stop apache2" --post-hook "systemctl start apache2" --rsa-key-size 4096 -d $USER_SUBDOMAIN
      return 0
    fi
  fi
}

configure_database(){
	echo <<EOFMW "
#################################################################
#
# We will now create the mysql database called '$HOST_DB_DATABASE',
# and also setup a mysql database user '$HOST_DB_USER'.
#
#
# Warning: if the database exists it will be dropped, if the user
# exists the password will be reset. (Ctrl-c to abort)
#
# Please provide your mysql root password if required
#################################################################
"
EOFMW

	mysql -f -u root -p$MYSQL_ROOT_PASS -e <<EOSQL "DROP DATABASE IF EXISTS $HOST_DB_DATABASE ;
CREATE DATABASE $HOST_DB_DATABASE;
GRANT ALL PRIVILEGES ON $HOST_DB_DATABASE.* TO '$HOST_DB_USER'@'localhost' IDENTIFIED BY '$HOST_DB_PASS';
FLUSH PRIVILEGES;"
EOSQL
}

echo <<EOF "

#################################################################
#
# $(basename $0) will attempt to add a vhost to your system now.
# This script is provided as it is, no warraties implied. (Ctrl-c to abort)
#
# Be sure that your domain have the following DNS configuration:
#
# If you use a domain:
# @   3600  IN  A  172.27.171.106
# www.example.com.   3600  IN  A  YOUR_SERVER_IP
#
# If you use a subdomain:
#
# yoursubdomain.example.com.   3600  IN  A  YOUR_SERVER_IP
#
# If the dns setup is not correct, the setup will fail.
#
#################################################################
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

  PS3='Select an Installer for your domain: '
  options=("Nextcloud" "Wordpress" "None")
  select opt in "${options[@]}"
  do
    case $opt in
      "Nextcloud")
        echo "Nextcloud selected"
        USER_CMS_CHOICE=nextcloud
        break
        ;;
      "Wordpress")
        echo "Wordpress selected"
        USER_CMS_CHOICE=wordpress
        break
        ;;
      "None")
        USER_CMS_CHOICE=none
        break
        ;;
      *) echo invalid option;;
    esac
  done

  if [ $USER_CMS_CHOICE = "nextcloud" ] || [ $USER_CMS_CHOICE = "wordpress" ]; then
    USER_DB_SITE=1
  else
    read -p "Do you want to add a database? [y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      printf "\nPlease provide your MySQL-Root-Password when asked.\n"
      USER_DB_SITE=1
    else
      USER_DB_SITE=0
    fi
  fi

  HOST_LOCATION_USER=(${USER_MAINDOMAIN//./ })

  HOST_DB_USER=$HOST_LOCATION_USER'_usr'
  if [ $USER_DOMAIN_TYP = "0" ]; then
  HOST_DB_DATABASE=${USER_MAINDOMAIN/./_}
  fi
  if [ $USER_DOMAIN_TYP = "1" ]; then
  HOST_DB_DATABASE=${USER_SUBDOMAIN//./_}
  fi

  HOST_DB_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c10)

  USER_DOMAIN_HYPHEN=${USER_MAINDOMAIN/./-}
  USER_SUBDOMAIN_HYPHEN=${USER_SUBDOMAIN//./-}

  HOST_MAINDOMAIN_ROOT_LOCATION="/var/www/$USER_MAINDOMAIN"
  HOST_SUBDOMAIN_ROOT_LOCATION="/var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN"

  HOST_MAINDOMAIN_HTTPD_LOCATION="/var/www/$USER_MAINDOMAIN/htdocs"
  HOST_SUBDOMAIN_HTTPD_LOCATION="/var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN/htdocs"

  create_skeleton_dirs
  configure_fpm_pool
  if [ $WEBSRV = "nginx" ]; then
    configure_nginx_vhost
  elif [ $WEBSRV = "apache" ]; then
    configure_apache_vhost
  fi
  configure_logrotate
  configure_letsencrypt
  if [ $USER_DB_SITE = "1" ]; then
  configure_database
  fi

  if [ $USER_CMS_CHOICE = "nextcloud" ]; then
    configure_nextcloud
  elif [ $USER_CMS_CHOICE = "wordpress" ]; then
    configure_wordpress
  fi

  [ $? -ne "0" ] && exit 1
fi

echo <<EOF "
#################################################################
#
# Your domain is ready to use:
#
"
EOF
echo "Domain: $USER_MAINDOMAIN"
if [ $USER_DOMAIN_TYP = "1" ]; then
  echo "Subdomain: $USER_SUBDOMAIN"
fi
echo "Absolute path domain: $HOST_MAINDOMAIN_ROOT_LOCATION"
if [ $USER_DOMAIN_TYP = "1" ]; then
  echo "Absolute path subdomain: $HOST_SUBDOMAIN_ROOT_LOCATION"
fi
echo "MySQL username: $HOST_DB_USER"
echo "MySQL password: $HOST_DB_PASS"
echo "MyMySQL database: $HOST_DB_DATABASE"
echo "Location owner: $HOST_LOCATION_USER"
echo <<EOF "
#
#
#################################################################
"
EOF
exit 0
