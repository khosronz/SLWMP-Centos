#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
# Version 0.9.0-dev

servicesCheck(){
ps cax | grep $1 > /dev/null
if [ $? -eq 0 ]; then
  return 1
else
  return 0
fi
}

source includes/install_web.sh
# Start Checks and initialize variables
if [ -e /etc/redhat-release ]; then
  DISTRO="centos"
elif [ -e /etc/debian_version ]; then
  DISTRO="debian"
fi

if [ $USER_PHP_VERSION = "php71" ]; then
  if [ $DISTRO = "debian" ]; then
    PHP_SRV_NAME=php7.1-fpm
    PHPPOOL_CONFIG_DIR=/etc/php/7.1/fpm/pool.d
  elif [ $DISTRO = "centos" ]; then
    PHP_SRV_NAME=php-php71-fpm
    PHPPOOL_CONFIG_DIR=/etc/php/php71/fpm/pool.d
  fi
elif [ $USER_PHP_VERSION = "php72" ]; then
  if [ $DISTRO = "debian" ]; then
    PHP_SRV_NAME=php7.2-fpm
    PHPPOOL_CONFIG_DIR=/etc/php/7.2/fpm/pool.d
  elif [ $DISTRO = "centos" ]; then
    PHP_SRV_NAME=php-php72-fpm
    PHPPOOL_CONFIG_DIR=/etc/php/php72/fpm/pool.d
  fi
elif [ $USER_PHP_VERSION = "php73" ]; then
  if [ $DISTRO = "debian" ]; then
    PHP_SRV_NAME=php7.3-fpm
    PHPPOOL_CONFIG_DIR=/etc/php/7.3/fpm/pool.d
  elif [ $DISTRO = "centos" ]; then
    PHP_SRV_NAME=php-php73-fpm
    PHPPOOL_CONFIG_DIR=/etc/php/php73/fpm/pool.d
  fi
fi

if [ $DISTRO = "debian" ]; then
  if [ -e /etc/apache2/apache2.conf ]; then
    WEBSRV="apache"
    WEBSRV_CONF_DIR="/etc/apache2/sites-available"
    WEBSRV_SVC_NAME="apache2"
  fi
elif [ $DISTRO = "centos" ]; then
  if [ -e /etc/httpd/conf/httpd.conf ]; then
    WEBSRV="apache"
    WEBSRV_CONF_DIR="/etc/httpd/conf.d"
    WEBSRV_SVC_NAME="httpd"
  fi
fi
if [ -e /etc/nginx/nginx.conf ]; then
  WEBSRV="nginx"
  WEBSRV_CONF_DIR="/etc/nginx/conf.d"
fi

# Stop Checks and initialize variables

create_skeleton_dirs() {
	useradd $HOST_LOCATION_USER -d /var/www/$USER_MAINDOMAIN
	usermod -aG $HOST_LOCATION_USER $WEBSRV

  if [ ! -d /var/www/$USER_MAINDOMAIN/htdocs ]; then
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
  chmod 755 /var/www/$USER_MAINDOMAIN
  chmod 755 /var/www/$USER_MAINDOMAIN/$USER_SUBDOMAIN
  chown -R $HOST_LOCATION_USER: /var/www/$USER_MAINDOMAIN
  return 0
}

configure_fpm_pool(){

  if [ $USER_DOMAIN_TYP = "0" ]; then
    cp templates/phpfpmpool.template $PHPPOOL_CONFIG_DIR/$USER_MAINDOMAIN.conf

	   sed -i s/DOMAINNAME_HYPHEN/$USER_DOMAIN_HYPHEN/g $PHPPOOL_CONFIG_DIR/$USER_MAINDOMAIN.conf
     sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g $PHPPOOL_CONFIG_DIR/$USER_MAINDOMAIN.conf
     sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' $PHPPOOL_CONFIG_DIR/$USER_MAINDOMAIN.conf
	   sed -i s/PHP-SOCKET/php73-fpm-$USER_DOMAIN_HYPHEN/g $PHPPOOL_CONFIG_DIR/$USER_MAINDOMAIN.conf
  fi
  if [ $USER_DOMAIN_TYP = "1" ]; then
    cp templates/phpfpmpool.template $PHPPOOL_CONFIG_DIR/$USER_SUBDOMAIN.conf

		sed -i s/DOMAINNAME_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g $PHPPOOL_CONFIG_DIR/$USER_SUBDOMAIN.conf
    sed -i s/HOST_LOCATION_USER/$HOST_LOCATION_USER/g $PHPPOOL_CONFIG_DIR/$USER_SUBDOMAIN.conf
    sed -i 's|'HOST_DOMAIN_FULL'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' $PHPPOOL_CONFIG_DIR/$USER_SUBDOMAIN.conf
		sed -i s/PHP-SOCKET/php73-fpm-$USER_SUBDOMAIN_HYPHEN/g $PHPPOOL_CONFIG_DIR/$USER_SUBDOMAIN.conf
  fi
  system reload $PHP_SRV_NAME
return 0
}

configure_apache_vhost() {
  if [ $USER_DOMAIN_TYP = "0" ]; then
    if [ $USER_PHP_VERSION = "php73" ]; then
      NGXSOCKET="/var/run/php73-fpm-$USER_DOMAIN_HYPHEN.sock"
    fi
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_DOMAIN_HYPHEN.sock"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_DOMAIN_HYPHEN.sock"
    fi
    if [ $DISTRO = "debian" ]; then
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
      sed -i s/#Protocols/Protocols/g /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
      sed -i s/#SSLSessionTickets/SSLSessionTickets/g /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
      sed -i s/DOMAIN_FULLNAME/$USER_MAINDOMAIN/g /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
      sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_MAINDOMAIN/g /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
      sed -i 's|'HOST_HTTPD_LOCATION'|'$HOST_MAINDOMAIN_HTTPD_LOCATION'|g' /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
      sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/apache2/sites-available/$USER_MAINDOMAIN.conf
      a2ensite -q $USER_MAINDOMAIN.conf
    fi
    if [ $DISTRO = "centos" ]; then
      if [ $USER_CMS_CHOICE = "none" ]; then
        cp templates/apache_default.template /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_CMS_CHOICE = "nextcloud" ]; then
        cp templates/apache_nextcloud.template /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      fi
      if [ $USER_CMS_CHOICE = "wordpress" ]; then
        cp templates/apache_wordpress.template /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      fi
      sed -i s/DOMAIN_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      sed -i s/DOMAIN_FULLNAME/$USER_MAINDOMAIN/g /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_MAINDOMAIN/g /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      sed -i 's|'HOST_HTTPD_LOCATION'|'$HOST_MAINDOMAIN_HTTPD_LOCATION'|g' /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/httpd/conf.d/$USER_MAINDOMAIN.conf
      systemctl -q reload httpd
    fi
  fi

  if [ $USER_DOMAIN_TYP = "1" ]; then
    if [ $USER_PHP_VERSION = "php73" ]; then
      NGXSOCKET="/var/run/php73-fpm-$USER_SUBDOMAIN_HYPHEN.sock"
    fi
    if [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_SUBDOMAIN_HYPHEN.sock"
    fi
    if [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_SUBDOMAIN_HYPHEN.sock"
    fi
    if [ $DISTRO = "debian" ]; then
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
      sed -i s/#Protocols/Protocols/g /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
      sed -i s/#SSLSessionTickets/SSLSessionTickets/g /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
      sed -i s/DOMAIN_FULLNAME/$USER_SUBDOMAIN/g /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
      sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_SUBDOMAIN/g /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
      sed -i 's|'HOST_HTTPD_LOCATION'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
      sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/apache2/sites-available/$USER_SUBDOMAIN.conf
      a2ensite -q $USER_SUBDOMAIN.conf
    fi
    if [ $DISTRO = "centos" ]; then
      if [ $USER_CMS_CHOICE = "none" ]; then
        cp templates/apache_default.template /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      fi
      if [ $USER_CMS_CHOICE = "nextcloud" ]; then
        cp templates/apache_nextcloud.template /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      fi
      if [ $USER_CMS_CHOICE = "wordpress" ]; then
        cp templates/apache_default.template /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      fi
      sed -i s/DOMAIN_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      sed -i s/DOMAIN_FULLNAME/$USER_SUBDOMAIN/g /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_SUBDOMAIN/g /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      sed -i 's|'HOST_HTTPD_LOCATION'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/httpd/conf.d/$USER_SUBDOMAIN.conf
      systemctl -q reload httpd
    fi
  fi
  if [ $USER_DOMAIN_TYP = "2" ]; then
    if [ $USER_DOMAIN_REDIRECT_TYP = "0" ]; then
      sed -i 's/\<ServerAlias\>/& $USER_REDIRECT_SOURCE_DOMAIN/' $WEBSRV_CONF_DIR/$USER_REDIRECT_TARGET_DOMAIN.conf
      if [ $DISTRO = "centos" ]; then
        systemctl -q reload httpd
      fi
      if [ $DISTRO = "debian" ]; then
        a2ensite -q $USER_REDIRECT_TARGET_DOMAIN.conf
        systemctl -q reload apache2
      fi
    elif [ $USER_DOMAIN_REDIRECT_TYP = "1" ]; then
      cp templates/apache_redirect.template $WEBSRV_CONF_DIR/$USER_REDIRECT_SOURCE_DOMAIN.conf
      sed -i s/DOMAIN_FULLNAME/$USER_REDIRECT_SOURCE_DOMAIN/g $WEBSRV_CONF_DIR/$USER_REDIRECT_SOURCE_DOMAIN.conf
      sed -i 's|'TARGET_DOMAINNAME'|'$USER_REDIRECT_TARGET_DOMAIN'|g' $WEBSRV_CONF_DIR/$USER_REDIRECT_SOURCE_DOMAIN.conf
      sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_REDIRECT_SOURCE_DOMAIN/g $WEBSRV_CONF_DIR/$USER_REDIRECT_SOURCE_DOMAIN.conf
      if [ $DISTRO = "centos" ]; then
        systemctl -q reload httpd
      fi
      if [ $DISTRO = "debian" ]; then
        a2ensite -q $USER_REDIRECT_SOURCE_DOMAIN.conf
        systemctl -q reload apache2
      fi
    fi
  fi
  return 0
}

configure_nginx_vhost(){
  if [ $USER_DOMAIN_TYP = "0" ]; then
    if [ $USER_PHP_VERSION = "php73" ]; then
      NGXSOCKET="/var/run/php73-fpm-$USER_DOMAIN_HYPHEN.sock;"
    elif [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_DOMAIN_HYPHEN.sock;"
    elif [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_DOMAIN_HYPHEN.sock;"
    elif [ $USER_CMS_CHOICE = "none" ]; then
      cp templates/nginx_default.template /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    elif [ $USER_CMS_CHOICE = "nextcloud" ]; then
      cp templates/nginx_nextcloud.template /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    elif [ $USER_CMS_CHOICE = "wordpress" ]; then
      cp templates/nginx_wordpress.template /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    fi
    sed -i s/DOMAIN_HYPHEN/$USER_DOMAIN_HYPHEN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i s/DOMAIN_FULLNAME/$USER_MAINDOMAIN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
	  sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_MAINDOMAIN/g /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
	  sed -i 's|'DOMAIN_HTTPD_LOCATION'|'$HOST_MAINDOMAIN_HTTPD_LOCATION'|g' /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
    sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_MAINDOMAIN_ROOT_LOCATION'|g' /etc/nginx/conf.d/$USER_MAINDOMAIN.conf
  elif [ $USER_DOMAIN_TYP = "1" ]; then
    if [ $USER_PHP_VERSION = "php73" ]; then
      NGXSOCKET="/var/run/php73-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    elif [ $USER_PHP_VERSION = "php72" ]; then
      NGXSOCKET="/var/run/php72-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    elif [ $USER_PHP_VERSION = "php71" ]; then
      NGXSOCKET="/var/run/php71-fpm-$USER_SUBDOMAIN_HYPHEN.sock;"
    elif [ $USER_CMS_CHOICE = "none" ]; then
      cp templates/nginx_default.template /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    elif [ $USER_CMS_CHOICE = "nextcloud" ]; then
      cp templates/nginx_nextcloud.template /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    elif [ $USER_CMS_CHOICE = "wordpress" ]; then
      cp templates/nginx_wordpress.template /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    fi
    sed -i s/DOMAIN_HYPHEN/$USER_SUBDOMAIN_HYPHEN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i 's|'NGXSOCKET'|'$NGXSOCKET'|g' /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i s/DOMAIN_FULLNAME/$USER_SUBDOMAIN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
	  sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_SUBDOMAIN/g /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
	  sed -i 's|'DOMAIN_HTTPD_LOCATION'|'$HOST_SUBDOMAIN_HTTPD_LOCATION'|g' /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
    sed -i 's|'HOST_ROOT_LOCATION'|'$HOST_SUBDOMAIN_ROOT_LOCATION'|g' /etc/nginx/conf.d/$USER_SUBDOMAIN.conf
  elif [ $USER_DOMAIN_TYP = "2" ]; then
    if [ $USER_DOMAIN_REDIRECT_TYP = "0" ]; then
      sed -i '/server_name /s/;/ $USER_REDIRECT_SOURCE_DOMAIN;/' /etc/nginx/conf.d/$USER_REDIRECT_TARGET_DOMAIN.conf
    elif [ $USER_DOMAIN_REDIRECT_TYP = "1" ]; then
      cp templates/nginx_redirect.template /etc/nginx/conf.d/$USER_REDIRECT_SOURCE_DOMAIN.conf
      sed -i s/DOMAIN_FULLNAME/$USER_REDIRECT_SOURCE_DOMAIN/g /etc/nginx/conf.d/$USER_REDIRECT_SOURCE_DOMAIN.conf
      sed -i 's|'TARGET_DOMAINNAME'|'$USER_REDIRECT_TARGET_DOMAIN'|g' /etc/nginx/conf.d/$USER_REDIRECT_SOURCE_DOMAIN.conf
      sed -i s/SSL_DOMAINNAME_FULLNAME/$USER_REDIRECT_SOURCE_DOMAIN/g /etc/nginx/conf.d/$USER_REDIRECT_SOURCE_DOMAIN.conf
    fi
  fi
	return 0
}

configure_logrotate() {
  if [ $WEBSRV = "nginx" ]; then
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
    elif [ $USER_DOMAIN_TYP = "1" ]; then
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
  elif [ $DISTRO = "centos" ]; then
    if [ $WEBSRV = "apache" ]; then
    cat >> /etc/logrotate.d/httpd <<EOL
    $HOST_ROOT_LOCATION/logs/*.log {
    daily
    missingok
    notifempty
    sharedscripts
    delaycompress
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
    endscript
  }
EOL
    fi
  elif [ $DISTRO = "debian" ]; then
    if [ $WEBSRV = "apache" ]; then
    cat >> /etc/logrotate.d/apache2 <<EOL
    $HOST_ROOT_LOCATION/logs/*.log {
            daily
            missingok
            rotate 14
            compress
            delaycompress
            notifempty
            create 640 root adm
            sharedscripts
            postrotate
                    if /etc/init.d/apache2 status > /dev/null ; then \
                        /etc/init.d/apache2 reload > /dev/null; \
                    fi;
            endscript
            prerotate
                    if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
                            run-parts /etc/logrotate.d/httpd-prerotate; \
                    fi; \
            endscript
    }
EOL
    fi
  fi
  return 0
}

configure_letsencrypt() {
  # Redirect Typ 0 = Alias / Redirect Typ 1 = Redirect
  if [ $WEBSRV = "nginx" ]; then
    if [ $USER_DOMAIN_TYP = "0" ]; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_MAINDOMAIN --non-interactive --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN
      return 0
    elif [ $USER_DOMAIN_TYP = "1" ]; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_MAINDOMAIN --non-interactive --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN -d $USER_SUBDOMAIN
      return 0
    elif [ $USER_DOMAIN_TYP = "2" ] && [ $USER_DOMAIN_REDIRECT_TYP = "0" ] ; then
      # First we are looking for the row with the servernames, then we are looking for all entries until the end of the row. SED remove the ; and add -d
      LE_EXISTING_DOMAINNAMES=grep 'server_name ' $WEBSRV_CONF_DIR/$USER_MAINDOMAIN -m 1 | awk '{for (i=1;i<=1;i++){$i=""};print}' | sed 's/;//g' | sed 's/ / -d /g'
      certbot certonly --standalone --expand --agree-tos --email hostmaster@$USER_EXISTING_DOMAIN --non-interactive --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --rsa-key-size 4096 -d $USER_REDIRECT_SOURCE_DOMAIN $LE_EXISTING_DOMAINNAMES
      return 0
    elif [ $USER_DOMAIN_TYP = "2" ] && [ $USER_DOMAIN_REDIRECT_TYP = "1" ] ; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_REDIRECT_SOURCE_DOMAIN --non-interactive --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --rsa-key-size 4096 -d $USER_REDIRECT_SOURCE_DOMAIN
      return 0
    fi
  fi
  if [ $WEBSRV = "apache" ]; then
    if [ $USER_DOMAIN_TYP = "0" ]; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_MAINDOMAIN --non-interactive --pre-hook "systemctl stop $WEBSRV_SVC_NAME" --post-hook "systemctl start $WEBSRV_SVC_NAME" --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN
      return 0
    elif [ $USER_DOMAIN_TYP = "1" ]; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_MAINDOMAIN --non-interactive --pre-hook "systemctl stop $WEBSRV_SVC_NAME" --post-hook "systemctl start $WEBSRV_SVC_NAME" --rsa-key-size 4096 -d $USER_MAINDOMAIN -d www.$USER_MAINDOMAIN -d $USER_SUBDOMAIN
      return 0
    elif [ $USER_DOMAIN_TYP = "2" ] && [ $USER_DOMAIN_REDIRECT_TYP = "0" ]; then
      LE_EXISTING_DOMAINNAMES=grep 'ServerAlias' $WEBSRV_CONF_DIR/$USER_MAINDOMAIN -m 1 | awk '{for (i=1;i<=1;i++){$i=""};print}' | sed 's/ / -d /g'
      certbot certonly --standalone --expand --agree-tos --email hostmaster@$USER_EXISTING_DOMAIN --non-interactive --pre-hook "systemctl stop $WEBSRV_SVC_NAME" --post-hook "systemctl start $WEBSRV_SVC_NAME" --rsa-key-size 4096 -d $USER_REDIRECT_SOURCE_DOMAIN $LE_EXISTING_DOMAINNAMES
      return 0
    elif [ $USER_DOMAIN_TYP = "2" ] && [ $USER_DOMAIN_REDIRECT_TYP = "1" ]; then
      certbot certonly --standalone --agree-tos --email hostmaster@$USER_REDIRECT_SOURCE_DOMAIN --non-interactive --pre-hook "systemctl stop $WEBSRV_SVC_NAME" --post-hook "systemctl start $WEBSRV_SVC_NAME" --rsa-key-size 4096 -d $USER_REDIRECT_SOURCE_DOMAIN
      return 0
    fi
  fi
  return 0
}

configure_database(){
	echo <<EOFMW "
#################################################################
#
# We will now create the mysql database called '$HOST_DB_DATABASE',
# and also setup a mysql database user '$HOST_DB_USER'.
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
#
# @                  3600  IN  A  YOUR_SERVER_IP
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
  PS3='Do you want to add a domain, subdomain or alias/redirect? '
  options=("Domain" "Subdomain" "Alias/Redirect")
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
      "Alias/Redirect")
        echo "Alias/Redirect selected"
        USER_DOMAIN_TYP=2
        break
        ;;
      *) echo invalid option;;
    esac
  done

  if [ $USER_DOMAIN_TYP -ne "2" ]; then

    read -p 'Domain [example.com]: ' USER_MAINDOMAIN
    if [ $USER_DOMAIN_TYP = "1" ]; then
      read -p 'Subdomain [subdomain.example.com]: ' USER_SUBDOMAIN
    fi

    PS3='Select the PHP for your domain: '
    options=("PHP 7.1" "PHP 7.2" "PHP 7.3")
    select opt in "${options[@]}"
    do
      case $opt in
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
        "PHP 7.3")
          echo "PHP 7.3 selected"
          USER_PHP_VERSION=php73
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
    HOST_DB_ADDITION=$(</dev/urandom tr -dc A-Za-z0-9 | head -c4)

    if [ $USER_DOMAIN_TYP = "0" ]; then
      HOST_DB_USER=$HOST_LOCATION_USER'_usr_'$HOST_DB_ADDITION
    elif [ $USER_DOMAIN_TYP = "1" ]; then
      HOST_DB_USER=$HOST_LOCATION_USER'_usr_'$HOST_DB_ADDITION
    fi

    if [ $USER_DOMAIN_TYP = "0" ]; then
    HOST_DB_DATABASE=${USER_MAINDOMAIN//./_}
    elif [ $USER_DOMAIN_TYP = "1" ]; then
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
  fi # if [ $USER_DOMAIN_TYP -ne "2" ]; then
  if [ $USER_DOMAIN_TYP = "2" ]; then
    clear
    PS3='Select the domain forwarding typ: '
    options=("Alias" "Redirect")
    select opt in "${options[@]}"
    do
      case $opt in
        "Alias")
          echo "Alias selected"
          USER_DOMAIN_REDIRECT_TYP=0
          break
          ;;
        "Redirect")
          echo "Redirect selected"
          USER_DOMAIN_REDIRECT_TYP=1
          break
          ;;
        *) echo invalid option;;
      esac
    done
    if [ $USER_DOMAIN_REDIRECT_TYP = "0" ]; then
      read -p 'Enter the target domain on this server: ' USER_EXISTING_DOMAIN
      USER_REDIRECT_TARGET_DOMAIN=(${USER_REDIRECT_TARGET_DOMAIN//./ })

      if [ -e $WEBSRV_CONF_DIR/$USER_REDIRECT_TARGET_DOMAIN.conf ]; then
        read -p 'Alias domain which should be added: ' USER_ALIAS_DOMAIN
        configure_letsencrypt
      else
        echo "Domain not exists on the server. Exit."
        exit 2
      fi

    elif [ $USER_DOMAIN_REDIRECT_TYP = "1" ]; then
      read -p 'Source Domain [(subdomain.)example.com]: ' USER_REDIRECT_SOURCE_DOMAIN
      echo
      read -p 'Target Domain [(subdomain.)example.com]: ' USER_REDIRECT_TARGET_DOMAIN
      echo
      configure_letsencrypt
      if [ $WEBSRV = "nginx" ]; then
        configure_nginx_vhost
      elif [ $WEBSRV = "apache" ]; then
        configure_apache_vhost
      fi # if [ $WEBSRV = "nginx" ]; then
    fi # elif [ $USER_DOMAIN_REDIRECT_TYP = "1"]; then
  fi # if [ $USER_DOMAIN_TYP = "2"]; then
fi # if [[ $REPLY =~ ^[Yy]$ ]]

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
echo "Location owner: $HOST_LOCATION_USER"
if [ "$USER_DB_SITE" = "1" ]; then
  echo "MySQL username: $HOST_DB_USER"
  echo "MySQL password: $HOST_DB_PASS"
  echo "MySQL database: $HOST_DB_DATABASE"
fi
echo <<EOF "
#
#
#################################################################
"
EOF
exit 0
