#!/bin/bash

# Copyright original script by Rimuhosting.com
# Copyright 2017 Tim Scharner (https://scharner.me)
# Version 0.3.0-beta

## Detect distro version
if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi

servicesCheck(){
ps cax | grep $1 > /dev/null
if [ $? -eq 0 ]; then
  return 1
else
  return 0
fi
}

#if servicesCheck "nginx"; then
#echo "fail"
#else
#echo "laeft"
#fi

install_mariadb(){

	if servicesCheck "mysql"; then
		echo "#################################################################"
                echo "# mysql server not running, MariaDB will now be installed"
                echo "#################################################################"

                MYSQL_ROOT_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c14)

                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  apt install software-properties-common dirmngr -y
                  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
                  add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.2/debian stretch main'

                  apt update
                  DEBIAN_FRONTEND=noninteractive apt-get install mariadb-server mariadb-client -y

                  apt install expect -y

                  expect -f - <<-EOF
                  set timeout 10
                  spawn mysql_secure_installation
                  expect "Enter current password for root (enter for none):"
                  send -- "\r"
                  expect "Set root password?"
                  send -- "y\r"
                  expect "New password:"
                  send -- "${MYSQL_ROOT_PASS}\r"
                  expect "Re-enter new password:"
                  send -- "${MYSQL_ROOT_PASS}\r"
                  expect "Remove anonymous users?"
                  send -- "y\r"
                  expect "Disallow root login remotely?"
                  send -- "y\r"
                  expect "Remove test database and access to it?"
                  send -- "y\r"
                  expect "Reload privilege tables now?"
                  send -- "y\r"
                  expect eof
EOF

                  apt remove --purge expect -y

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

                  yum install expect -y

                  expect -f - <<-EOF
                  set timeout 10
                  spawn mysql_secure_installation
                  expect "Enter current password for root (enter for none):"
                  send -- "\r"
                  expect "Set root password?"
                  send -- "y\r"
                  expect "New password:"
                  send -- "${MYSQL_ROOT_PASS}\r"
                  expect "Re-enter new password:"
                  send -- "${MYSQL_ROOT_PASS}\r"
                  expect "Remove anonymous users?"
                  send -- "y\r"
                  expect "Disallow root login remotely?"
                  send -- "y\r"
                  expect "Remove test database and access to it?"
                  send -- "y\r"
                  expect "Reload privilege tables now?"
                  send -- "y\r"
                  expect eof
EOF

                  yum remove expect -y
                fi

                systemctl enable mariadb
                systemctl start mariadb
                # Next step is mysql_secure_installation

	fi

	return 0
}

install_nginx() {
    if servicesCheck "nginx"; then
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
    fi
}

install_phpfpm() {
if servicesCheck "php-fpm"; then
    echo "#################################################################"
                echo "# php-fpm proccess not running, will now be installed"
                echo "#################################################################"

                if [ $DISTRO = "debian" ]; then
                  #We will using sources from https://deb.sury.org/
                  apt-get install apt-transport-https lsb-release ca-certificates -y
                  cd /tmp && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
                  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
                  rm /tmp/php.gpg
                  apt-get update

                  apt install php7.0-fpm php7.0-mysql php7.0-gd php7.0-curl php7.0-mbstring php7.0-mcrypt php7.0-xml php7.0-xmlrpc -y # more to come
                  # Start all these things...
                  systemctl start php7.0-fpm
                  systemctl enable php7.0-fpm
                fi
                if [ $DISTRO = "centos" ]; then
                  # Using Remis Repo https://rpms.remirepo.net/
                  yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
                  yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
                  yum install yum-utils -y

                  yum install php70-php-fpm php70-php-mysql php70-php-gd php70-php-curl php70-php-mbstring php70-php-mcrypt php70-php-xml php70-php-xmlrpc -y # more to come
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
configure_centos() {
  # Firewalld rules for nginx
  echo "Configure some CentOS related things..."
  echo "Adding firewalld rules for nginx"
  firewall-cmd --permanent --zone=public --add-service=http
  firewall-cmd --permanent --zone=public --add-service=https
  firewall-cmd --reload
  # Disabling SELINUX for now
  echo "Disabling SELINUX..."
  sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config

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
# ATTENTION CentOS users: This script will deactivate SELINUX!
#
#################################################################
"
EOF

echo <<EOF "
$(basename $0) will attempt to install SLEMP.
This script is provided as it is, no warraties implied.
"
EOF

read -p "Do you want to start the installation? y/n" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    install_nginx
    install_phpfpm
    install_letsencrypt
    install_mariadb
    if [ $DISTRO = "centos" ]; then
      configure_centos
    fi
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
# !!! YOUR MYSQL-ROOT-PASSWORD: $MYSQL_ROOT_PASS !!!
# Be sure to safe it on a safe place
# CentOS users have to restart their server to apply the changes to SELINUX!
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
