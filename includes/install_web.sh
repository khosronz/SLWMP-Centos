#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
# Version 0.6.1

configure_nextcloud() {
echo <<EOFMW "
#################################################################
#
# We will now download and install the latest version of Nextcloud!
# Everything will be setup automatically fory you.
#
# Please enter your desired Username and Password for Nextcloud now.
#
#################################################################
"
EOFMW
  read -p "Your Nextcloud Username: " USER_NC_USERNAME
  echo
  read -p "Your Nextcloud User password: " USER_NC_PASSWD
  echo

  wget https://download.nextcloud.com/server/releases/latest.tar.bz2 -O /tmp/nextcloud.tar.bz2
  tar -xjf /tmp/nextcloud.tar.bz2 -C /tmp
  rm -f /tmp/nextcloud.tar.bz2

  if ! servicesCheck "redis-server"; then
    usermod -aG redis $HOST_LOCATION_USER
  fi

  if [ $USER_DOMAIN_TYP = "0" ]; then
    mv /tmp/nextcloud/* $HOST_MAINDOMAIN_HTTPD_LOCATION
    mkdir $HOST_MAINDOMAIN_ROOT_LOCATION/data
    chown -R $HOST_LOCATION_USER: $HOST_MAINDOMAIN_HTTPD_LOCATION/*
    chown -R $HOST_LOCATION_USER: $HOST_MAINDOMAIN_ROOT_LOCATION/data
    chmod +x $HOST_MAINDOMAIN_HTTPD_LOCATION/occ
cat > $HOST_MAINDOMAIN_HTTPD_LOCATION/config/config.php <<EOL
<?php
\$CONFIG = array (
  'trusted_domains' =>
  array (
    0 => '$USER_MAINDOMAIN',
  ),
  'datadirectory' => '$HOST_MAINDOMAIN_ROOT_LOCATION/data',
  'overwrite.cli.url' => 'https://$USER_MAINDOMAIN',
  'htaccess.RewriteBase' => '/',
  'dbtype' => 'mysql',
  'dbname' => '$HOST_DB_DATABASE',
  'dbhost' => 'localhost',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => '$HOST_DB_USER',
  'dbpassword' => '$HOST_DB_PASS',
  'memcache.local' => '\OC\Memcache\APCu',
EOL
  if ! servicesCheck "redis-server"; then
  cat >> $HOST_MAINDOMAIN_HTTPD_LOCATION/config/config.php <<EOL
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
    'host' => '/var/run/redis/redis.sock',
    'port' => 0,
    'timeout' => 0.0,
  ),
EOL
  fi
cat >> $HOST_MAINDOMAIN_HTTPD_LOCATION/config/config.php <<EOL
  'installed' => false,
);
EOL
    chown $HOST_LOCATION_USER: $HOST_MAINDOMAIN_HTTPD_LOCATION/config/config.php
    sudo -u $HOST_LOCATION_USER php $HOST_MAINDOMAIN_HTTPD_LOCATION/occ maintenance:install --database "mysql" --database-name "$HOST_DB_DATABASE"  --database-user "$HOST_DB_USER" --database-pass "$HOST_DB_PASS" --admin-user "$USER_NC_USERNAME" --admin-pass "$USER_NC_PASSWD" --data-dir "$HOST_MAINDOMAIN_ROOT_LOCATION/data"
    sudo -u $HOST_LOCATION_USER php $HOST_MAINDOMAIN_HTTPD_LOCATION/occ config:system:set trusted_domains 0 --value=$USER_MAINDOMAIN
    sudo -u $HOST_LOCATION_USER php $HOST_MAINDOMAIN_HTTPD_LOCATION/occ config:system:set overwrite.cli.url --value=https://$USER_MAINDOMAIN
    echo "*/15 * * * * php -f $HOST_MAINDOMAIN_HTTPD_LOCATION/cron.php > /dev/null 2>&1" | crontab -u $HOST_LOCATION_USER -
    sudo -u $HOST_LOCATION_USER php $HOST_MAINDOMAIN_HTTPD_LOCATION/occ background:cron

  elif [ $USER_DOMAIN_TYP = "1" ]; then
    mv /tmp/nextcloud/* $HOST_SUBDOMAIN_HTTPD_LOCATION
    mkdir $HOST_SUBDOMAIN_ROOT_LOCATION/data
    chown -R $HOST_LOCATION_USER: $HOST_SUBDOMAIN_HTTPD_LOCATION/*
    chown -R $HOST_LOCATION_USER: $HOST_SUBDOMAIN_ROOT_LOCATION/data
    chmod +x $HOST_SUBDOMAIN_HTTPD_LOCATION/occ
    cat > $HOST_SUBDOMAIN_HTTPD_LOCATION/config/config.php <<EOL
    <?php
    \$CONFIG = array (
      'trusted_domains' =>
      array (
        0 => 'localhost',
      ),
      'datadirectory' => '$HOST_SUBDOMAIN_ROOT_LOCATION/data',
      'overwrite.cli.url' => 'https://$USER_SUBDOMAIN',
      'htaccess.RewriteBase' => '/',
      'dbtype' => 'mysql',
      'dbname' => '$HOST_DB_DATABASE',
      'dbhost' => 'localhost',
      'dbport' => '',
      'dbtableprefix' => 'oc_',
      'mysql.utf8mb4' => true,
      'dbuser' => '$HOST_DB_USER',
      'dbpassword' => '$HOST_DB_PASS',
      'memcache.local' => '\OC\Memcache\APCu',
EOL
      if ! servicesCheck "redis-server"; then
      cat >> $HOST_SUBDOMAIN_HTTPD_LOCATION/config/config.php <<EOL
      'memcache.locking' => '\OC\Memcache\Redis',
      'redis' => array(
        'host' => '/var/run/redis/redis.sock',
        'port' => 0,
        'timeout' => 0.0,
      ),
EOL
      fi
    cat >> $HOST_SUBDOMAIN_HTTPD_LOCATION/config/config.php <<EOL
      'installed' => false,
    );
EOL
    chown $HOST_LOCATION_USER: $HOST_SUBDOMAIN_HTTPD_LOCATION/config/config.php
    sudo -u $HOST_LOCATION_USER php $HOST_SUBDOMAIN_HTTPD_LOCATION/occ maintenance:install --database "mysql" --database-name "$HOST_DB_DATABASE"  --database-user "$HOST_DB_USER" --database-pass "$HOST_DB_PASS" --admin-user "$USER_NC_USERNAME" --admin-pass "$USER_NC_PASSWD" --data-dir "$HOST_SUBDOMAIN_ROOT_LOCATION/data"
    sudo -u $HOST_LOCATION_USER php $HOST_SUBDOMAIN_HTTPD_LOCATION/occ config:system:set trusted_domains 0 --value=$USER_SUBDOMAIN
    sudo -u $HOST_LOCATION_USER php $HOST_SUBDOMAIN_HTTPD_LOCATION/occ config:system:set overwrite.cli.url --value=https://$USER_SUBDOMAIN

    echo "*/15 * * * * php -f $HOST_SUBDOMAIN_HTTPD_LOCATION/cron.php > /dev/null 2>&1" | crontab -u $HOST_LOCATION_USER -
    sudo -u $HOST_LOCATION_USER php $HOST_SUBDOMAIN_HTTPD_LOCATION/occ background:cron
  fi

  rm -rf /tmp/nextcloud
  echo <<EOFMW "
  #################################################################
  #
  # Your Nextcloud installation is finished!
  # Open a browser and go to your domain to login.
  #
  # Login with your previous provided login credentials!
  #
  #################################################################
  "
EOFMW
  return 0
}

configure_wordpress() {
echo <<EOFMW "
  #################################################################
  #
  # We will now download and install the latest version of Wordpress!
  # After download and installation you have to create your account.
  #
  #################################################################
  "
EOFMW
  wget --no-check-certificate http://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
  tar -xz -C /tmp -f /tmp/wordpress.tar.gz
  rm -f /tmp/wordpress.tar.gz

  if [ $USER_DOMAIN_TYP = "0" ]; then
    if [ -d $HOST_MAINDOMAIN_HTTPD_LOCATION ]; then
      echo "#################################################################"
      echo "# Directory $HOST_MAINDOMAIN_HTTPD_LOCATION already exists, move away and proceed? (Ctrl-c to abort)"
      echo "#################################################################"
      mv -v $HOST_MAINDOMAIN_HTTPD_LOCATION $HOST_MAINDOMAIN_HTTPD_LOCATION.$(date '+%s')
    fi
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

  elif [ $USER_DOMAIN_TYP = "1" ]; then
    if [ -d $HOST_SUBDOMAIN_HTTPD_LOCATION ]; then
      echo "#################################################################"
      echo "# Directory $HOST_SUBDOMAIN_HTTPD_LOCATION already exists, move away and proceed? (Ctrl-c to abort)"
      echo "#################################################################"
      mv -v $HOST_SUBDOMAIN_HTTPD_LOCATION $HOST_SUBDOMAIN_HTTPD_LOCATION.$(date '+%s')
    fi
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
echo <<EOFMW "
    #################################################################
    #
    # Your Wordpress installation is now finished.
    # Open a browser and go to your domain to finish the setup!
    #
    #################################################################
    "
EOFMW
  return 0
}
