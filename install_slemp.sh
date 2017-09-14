#!/bin/bash

# Copyright original script by Rimuhosting.com
# Copyright 2017 Tim Scharner (https://scharner.me)
# Version 0.2.0-alpa

## Detect distro version
if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi

install_mariadb(){

	if ! ps aux | grep -q '^mysql.*mysqld'; then
		echo "#################################################################"
                echo "# mysql server not running, MariaDB will now be installed"
                echo "#################################################################"

                MYSQL_ROOT_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c14)

                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  apt-get install software-properties-common dirmngr -y
                  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
                  add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.2/debian stretch main'

                  apt-get update
                  apt-get install mariadb-server mariadb-client -y
                fi
                if [ $DISTRO = "centos" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx

                  cat >/etc/yum.repos.d/MariaDB.repo <<EOL
                  [mariadb]
                  name = MariaDB
                  baseurl = http://yum.mariadb.org/10.2/centos7-amd64
                  gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
                  gpgcheck=1
EOL

                  rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
                  yum update && yum install MariaDB-server MariaDB-client -y
                fi

                systemctl enable mariadb
                systemctl start mariadb
                # Next step is mysql_secure_installation

                #echo "--> Wait 5s to boot up MySQL"
                #sleep 5

                #apt install expect -y

                #SECURE_MYSQL=$(expect -c "
                #set timeout 10
                #spawn mysql_secure_installation
                #expect \"Enter current password for root (enter for none):\"
                #send \"$MYSQL\r\"
                #expect \"Change the root password?\"
                #send \"n\r\"
                #expect \"Remove anonymous users?\"
                #send \"y\r\"
                #expect \"Disallow root login remotely?\"
                #send \"y\r\"
                #expect \"Remove test database and access to it?\"
                #send \"y\r\"
                #expect \"Reload privilege tables now?\"
                #send \"y\r\"
                #expect eof
                #")

                #echo "$SECURE_MYSQL"

                #apt remove --purge expect -y

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
                  cd /tmp && wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key
                  rm /tmp/nginx_signing.key
                  apt update && apt install nginx

                  # Because default path for nginx is /usr/share we have to add www
                  mkdir /var/www
              	fi
                if [ $DISTRO = "centos" ]; then
                  # Addd sources for centos from nginx website.
                  cd /tmp && wget http://nginx.org/keys/nginx_signing.key
                  cat >/etc/yum.repos.d/nginx.repo <<EOL
                  [nginx]
                  name=nginx repo
                  baseurl=http://nginx.org/packages/mainline/centos/7/$basearch/
                  gpgcheck=0
                  enabled=1
EOL
                  rpm --import nginx_signing.key
                  yum update && yum install nginx
                  rm -f /tmp/nginx_signing.key
                fi
                # First, we not longer show nginx used version
                sed -i '/#gzip  on;/a server_tokens off;' /etc/nginx/nginx.conf
                # Next, we changed some backlog variables
                echo "net.core.netdev_max_backlog=4096" >> /etc/sysctl.conf
                echo "net.core.somaxconn=4096" >> /etc/sysctl.conf
                echo "net.ipv4.tcp_max_syn_backlog=4096" >> /etc/sysctl.conf
                sysctl -p

                systemctl start nginx
                systemctl enable nginx

                # Adding firewall rules for nginx
                if [ $DISTRO = "centos" ]; then
                  firewall-cmd --permanent --zone=public --add-service=http
                  firewall-cmd --permanent --zone=public --add-service=https
                  firewall-cmd --reload
                fi
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
                  cd /tmp && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
                  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
                  rm /tmp/php.gpg
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

echo <<EOF "
$(basename $0) will attempt to install SLEMP.
This script is provided as it is, no warraties implied.
"
EOF

read -p "Do you want to start the installation? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    install_nginx
    install_phpfpm
    install_letsencrypt
    install_mariadb
    [ $? -ne "0" ] && exit 1
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
