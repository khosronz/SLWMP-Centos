#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
# Version 0.6.0-dev

configure_nextcloud() {
  wget https://download.nextcloud.com/server/releases/latest.tar.bz2 -O /tmp/nextcloud.tar.bz2
  tar xfvj -C /tmp -f /tmp/nextcloud.tar.bz2
  rm -f /tmp/nextcloud.tar.bz2

  if [ $USER_DOMAIN_TYP = "0" ]; then
    mv /tmp/nextcloud/ $HOST_MAINDOMAIN_HTTPD_LOCATION
    chown -R $HOST_LOCATION_USER: $HOST_MAINDOMAIN_HTTPD_LOCATION
  elif [ $USER_DOMAIN_TYP = "1" ]; then
    mv /tmp/nextcloud/ $HOST_SUBDOMAIN_HTTPD_LOCATION
    chown -R $HOST_LOCATION_USER: $HOST_SUBDOMAIN_HTTPD_LOCATION
  fi

  return 0
}

configure_wordpress() {

  wget --no-check-certificate http://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
  tar -xz -C /tmp -f /tmp/wordpress.tar.gz
  rm -f /tmp/wordpress.tar.gz

  if [ -d $WP_LOCATION ]; then
    echo "#################################################################"
    echo "# Directory $WP_LOCATION already exists, move away and proceed? (Ctrl-c to abort)"
    echo "#################################################################"
    mv -v $WP_LOCATION $WP_LOCATION.$(date '+%s')
  fi

  if [ $USER_DOMAIN_TYP = "0" ]; then
    mv /tmp/wordpress/ $HOST_MAINDOMAIN_HTTPD_LOCATION
    find $HOST_MAINDOMAIN_HTTPD_LOCATION -type d -exec chmod 755 {} \;
    find $HOST_MAINDOMAIN_HTTPD_LOCATION -type f -exec chmod 644 {} \;

    touch $HOST_MAINDOMAIN_HTTPD_LOCATION/robots.txt
    chown -R $HOST_LOCATION_USER: $HOST_MAINDOMAIN_HTTPD_LOCATION/wp-content $HOST_MAINDOMAIN_HTTPD_LOCATION/robots.txt
    cp $HOST_MAINDOMAIN_HTTPD_LOCATION/wp-config-sample.php $HOST_MAINDOMAIN_HTTPD_LOCATION/wp-config.php

    sed -i "s/^define('DB_NAME'.*);/define('DB_NAME', '$HOST_DB_DATABASE');/g"  $HOST_MAINDOMAIN_HTTPD_LOCATION/wp-config.php
    sed -i "s/^define('DB_USER'.*);/define('DB_USER', '$HOST_DB_USER');/g"  $HOST_MAINDOMAIN_HTTPD_LOCATION/wp-config.php
    sed -i "s/^define('DB_PASSWORD'.*);/define('DB_PASSWORD', '$HOST_DB_PASS');/g"  $HOST_MAINDOMAIN_HTTPD_LOCATION/wp-config.php

    SALTSLIST="AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT"

    for s in $SALTSLIST; do
      sed -i "s/^define('"$s".*);/define('"$s"', '"$(</dev/urandom tr -dc A-Za-z0-9 | head -c64)"');/g" $HOST_MAINDOMAIN_HTTPD_LOCATION/wp-config.php
    done
    chown -R $HOST_LOCATION_USER: $HOST_MAINDOMAIN_HTTPD_LOCATION

  elif [ $USER_DOMAIN_TYP = "1" ]; the
    mv /tmp/wordpress/ $HOST_SUBDOMAIN_HTTPD_LOCATION
    find $HOST_SUBDOMAIN_HTTPD_LOCATION -type d -exec chmod 755 {} \;
    find $HOST_SUBDOMAIN_HTTPD_LOCATION -type f -exec chmod 644 {} \;

    touch $HOST_SUBDOMAIN_HTTPD_LOCATION/robots.txt
    chown -R $HOST_LOCATION_USER: $HOST_SUBDOMAIN_HTTPD_LOCATION/wp-content $HOST_SUBDOMAIN_HTTPD_LOCATION/robots.txt
    cp $HOST_SUBDOMAIN_HTTPD_LOCATION/wp-config-sample.php $HOST_SUBDOMAIN_HTTPD_LOCATION/wp-config.php

    sed -i "s/^define('DB_NAME'.*);/define('DB_NAME', '$HOST_DB_DATABASE');/g"  $HOST_SUBDOMAIN_HTTPD_LOCATION/wp-config.php
    sed -i "s/^define('DB_USER'.*);/define('DB_USER', '$HOST_DB_USER');/g"  $HOST_SUBDOMAIN_HTTPD_LOCATION/wp-config.php
    sed -i "s/^define('DB_PASSWORD'.*);/define('DB_PASSWORD', '$HOST_DB_PASS');/g"  $HOST_SUBDOMAIN_HTTPD_LOCATION/wp-config.php

    SALTSLIST="AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT"

    for s in $SALTSLIST; do
      sed -i "s/^define('"$s".*);/define('"$s"', '"$(</dev/urandom tr -dc A-Za-z0-9 | head -c64)"');/g" $HOST_SUBDOMAIN_HTTPD_LOCATION/wp-config.php
    done
    chown -R $HOST_LOCATION_USER: $HOST_SUBDOMAIN_HTTPD_LOCATION
  fi
  return 0
}
