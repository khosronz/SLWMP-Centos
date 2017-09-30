#!/bin/bash

# Copyright original script by Rimuhosting.com
# Copyright 2017 Tim Scharner (https://scharner.me)
# Version 0.4.0

if [[ $EUID -ne 0 ]]; then
   echo "$(tput setaf 1)This script must be run as root$(tput sgr0)" 1>&2
   exit 1
fi

## Detect distro version
if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi

PHPVERSION="php71"

servicesCheck(){
ps cax | grep $1 > /dev/null
if [ $? -eq 0 ]; then
  return 1
else
  return 0
fi
}

install_mariadb(){

	if servicesCheck "mysql"; then
		echo "$(tput setaf 2)#################################################################"
                echo "# mysql server not running, MariaDB will now be installed"
                echo "#################################################################$(tput sgr0)"

                MYSQL_ROOT_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c14)

                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  apt install software-properties-common dirmngr -y
                  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
                  add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.2/debian stretch main'

                  apt update && apt install expect -y
                  DEBIAN_FRONTEND=noninteractive apt-get install mariadb-server mariadb-client -y

                  systemctl enable mariadb
                  systemctl start mariadb

                  expect -f - <<-EOF
                  set timeout 3
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
                  yum update -y && yum install MariaDB-server MariaDB-client expect -y

                  systemctl enable mariadb
                  systemctl start mariadb

                  SECURE_MYSQL=$(expect -c "

                  set timeout 3
                  spawn mysql_secure_installation
                  expect \"Enter current password for root (enter for none):\"
                  send \"\r\"
                  expect \"root password?\"
                  send \"y\r\"
                  expect \"New password:\"
                  send \"$MYSQL_ROOT_PASS\r\"
                  expect \"Re-enter new password:\"
                  send \"$MYSQL_ROOT_PASS\r\"
                  expect \"Remove anonymous users?\"
                  send \"y\r\"
                  expect \"Disallow root login remotely?\"
                  send \"y\r\"
                  expect \"Remove test database and access to it?\"
                  send \"y\r\"
                  expect \"Reload privilege tables now?\"
                  send \"y\r\"
                  expect eof
                  ")
                  echo "${SECURE_MYSQL}"

                  yum remove expect -y

                fi
  else
    echo "$(tput setaf 1)#################################################################"
                echo "# mysql server running, skipping installation..."
                echo "#################################################################"
	fi

	return 0
}

install_nginx() {
    if servicesCheck "nginx"; then
		echo "$(tput setaf 2)#################################################################"
                echo "# nginx server not running, will now be installed..."
                echo "#################################################################$(tput sgr0)"

                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" > /etc/apt/sources.list.d/nginx.list
                  echo "deb-src http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" >> /etc/apt/sources.list.d/nginx.list
                  cd /tmp && wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key
                  rm /tmp/nginx_signing.key
                  apt update && apt install nginx

              	fi
                if [ $DISTRO = "centos" ]; then
                  # Addd sources for centos from nginx website.
                  cd /tmp && wget http://nginx.org/keys/nginx_signing.key
                  rpm --import nginx_signing.key
cat >/etc/yum.repos.d/nginx.repo <<EOL
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOL
                  yum update -y && yum install nginx -y
                  rm -f /tmp/nginx_signing.key
                fi
                if [ ! -d "/var/www" ]; then
                  mkdir /var/www
                fi
                # First, we not longer show nginx used version
                sed -i '/#gzip  on;/a server_tokens off;' /etc/nginx/nginx.conf
                # Next, we changed some backlog variables
                echo "net.core.netdev_max_backlog=4096" >> /etc/sysctl.conf
                echo "net.core.somaxconn=4096" >> /etc/sysctl.conf
                echo "net.ipv4.tcp_max_syn_backlog=4096" >> /etc/sysctl.conf
                sysctl -p

                openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096

                systemctl start nginx
                systemctl enable nginx
    else
      echo "$(tput setaf 1)#################################################################"
                  echo "# nginx server running, skipping installation..."
                  echo "#################################################################$(tput sgr0)"
    fi
}

install_phpfpm() {
if servicesCheck "php-fpm"; then
    echo "$(tput setaf 2)#################################################################"
                echo "# php-fpm proccess not running, will now be installed"
                echo "#################################################################$(tput sgr0)"

                if [ $DISTRO = "debian" ]; then
                  #We will using sources from https://deb.sury.org/
                  apt-get install apt-transport-https lsb-release ca-certificates -y
                  cd /tmp && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
                  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
                  rm /tmp/php.gpg
                  apt-get update
                  if [ $PHPVERSION = "php72" ]; then
                    apt install php7.2-fpm php7.2-mysql php7.2-gd php7.2-cli php7.2-curl php7.2-mbstring php7.2-posix php7.2-mcrypt php7.2-xml php7.2-xmlrpc php7.2-intl php7.2-mcrypt php7.2-imagick php7.2-xml php7.2-zip -y
                    # Start all these things...
                    systemctl start php7.2-fpm
                    systemctl enable php7.2-fpm
                  fi
                  if [ $PHPVERSION = "php71" ]; then
                    apt install php7.1-fpm php7.1-mysql php7.1-gd php7.1-cli php7.1-curl php7.1-mbstring php7.1-posix php7.1-mcrypt php7.1-xml php7.1-xmlrpc php7.1-intl php7.1-mcrypt php7.1-imagick php7.1-xml php7.1-zip -y
                    # Start all these things...
                    systemctl start php7.1-fpm
                    systemctl enable php7.1-fpm
                  fi
                  if [ $PHPVERSION = "php70" ]; then
                    apt install php7.0-fpm php7.0-mysql php7.0-gd php7.0-cli php7.0-curl php7.0-mbstring php7.0-posix php7.0-mcrypt php7.0-xml php7.0-xmlrpc php7.0-intl php7.0-mcrypt php7.0-imagick php7.0-xml php7.0-zip -y
                    # Start all these things...
                    systemctl start php7.0-fpm
                    systemctl enable php7.0-fpm
                  fi
                  if [ $PHPVERSION = "all" ]; then
                    apt install php7.0-fpm php7.0-mysql php7.0-gd php7.0-cli php7.0-curl php7.0-mbstring php7.0-posix php7.0-mcrypt php7.0-xml php7.0-xmlrpc php7.0-intl php7.0-mcrypt php7.0-imagick php7.0-xml php7.0-zip -y
                    apt install php7.1-fpm php7.1-mysql php7.1-gd php7.1-cli php7.1-curl php7.1-mbstring php7.1-posix php7.1-mcrypt php7.1-xml php7.1-xmlrpc php7.1-intl php7.1-mcrypt php7.1-imagick php7.1-xml php7.1-zip -y
                    apt install php7.2-fpm php7.2-mysql php7.2-gd php7.2-cli php7.2-curl php7.2-mbstring php7.2-posix php7.2-mcrypt php7.2-xml php7.2-xmlrpc php7.2-intl php7.2-mcrypt php7.2-imagick php7.2-xml php7.2-zip -y
                    # Start all these things...
                    systemctl start php7.0-fpm
                    systemctl enable php7.0-fpm

                    systemctl start php7.1-fpm
                    systemctl enable php7.1-fpm

                    systemctl start php7.2-fpm
                    systemctl enable php7.2-fpm
                  fi
                fi
                if [ $DISTRO = "centos" ]; then
                  # Using Remis Repo https://rpms.remirepo.net/
                  yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
                  yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
                  yum update -y && yum install yum-utils -y
                  if [ $PHPVERSION = "php72" ]; then
                    yum install php72-php-fpm php72-php-mysql php72-php-gd php72-php-cli php72-php-curl php72-php-mbstring php72-php-posix php72-php-mcrypt php72-php-xml php72-php-xmlrpc php72-php-intl php72-php-mcrypt php72-php-imagick php72-php-xml php72-php-zip -y
                    # Start all these things...
                    systemctl start php72-php-fpm
                    systemctl enable php72-php-fpm
                  fi
                  if [ $PHPVERSION = "php71" ]; then
                    yum install php71-php-fpm php71-php-mysql php71-php-gd php71-php-cli php71-php-curl php71-php-mbstring php71-php-posix php71-php-mcrypt php71-php-xml php71-php-xmlrpc php71-php-intl php71-php-mcrypt php71-php-imagick php71-php-xml php71-php-zip -y
                    # Start all these things...
                    systemctl start php71-php-fpm
                    systemctl enable php71-php-fpm
                  fi
                  if [ $PHPVERSION = "php70" ]; then
                    yum install php70-php-fpm php70-php-mysql php70-php-gd php70-php-cli php70-php-curl php70-php-mbstring php70-php-posix php70-php-mcrypt php70-php-xml php70-php-xmlrpc php70-php-intl php70-php-mcrypt php70-php-imagick php70-php-xml php70-php-zip -y
                    systemctl start php70-php-fpm
                    systemctl enable php70-php-fpm
                  fi
                  if [ $PHPVERSION = "all" ]; then
                    yum install php70-php-fpm php70-php-mysql php70-php-gd php70-php-cli php70-php-curl php70-php-mbstring php70-php-posix php70-php-mcrypt php70-php-xml php70-php-xmlrpc php70-php-intl php70-php-mcrypt php70-php-imagick php70-php-xml php70-php-zip -y
                    yum install php71-php-fpm php71-php-mysql php71-php-gd php71-php-cli php71-php-curl php71-php-mbstring php71-php-posix php71-php-mcrypt php71-php-xml php71-php-xmlrpc php71-php-intl php71-php-mcrypt php71-php-imagick php71-php-xml php71-php-zip -y
                    yum install php72-php-fpm php72-php-mysql php72-php-gd php72-php-cli php72-php-curl php72-php-mbstring php72-php-posix php72-php-mcrypt php72-php-xml php72-php-xmlrpc php72-php-intl php72-php-mcrypt php72-php-imagick php72-php-xml php72-php-zip -y

                    systemctl start php70-php-fpm
                    systemctl enable php70-php-fpm

                    systemctl start php71-php-fpm
                    systemctl enable php71-php-fpm

                    systemctl start php72-php-fpm
                    systemctl enable php72-php-fpm
                  fi

                  return 0
                fi
else
  echo "$(tput setaf 1)#################################################################"
              echo "# php-fpm server running, skipping installation..."
              echo "#################################################################$(tput sgr0)"
fi
}

install_letsencrypt() {
  if [ $DISTRO = "debian" ]; then
    apt update && apt install certbot -y
  fi
  if [ $DISTRO = "centos" ]; then
    yum update && yum install certbot -y
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
 -p     Select which PHP-version do you want to use
 -h			this Help
"
USAGE
}

# Default PHP version,if nothing is choosen
PHPVERSION="php71"

## Parse args and execute tasks
while getopts 'p:h' option; do
	case $option in
	p)	PHPVERSION=$OPTARG;;
	h)	usage
		exit 0;;
	[?])	usage
		exit 1;;
    esac
done
shift $(($OPTIND - 1))

# for debuggging only

echo "CHOOSEN PHP Version: $PHPVERSION"

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
# $(tput setaf 1)Be warned:
# The installation need time, because we will generate a 4096 bit key for Diffie-Hellman!$(tput sgr0)
#
# $(tput setaf 1)ATTENTION CentOS users: This script will DEACTIVATE SELinux!
# You have to restart your server after installation!$(tput sgr0)
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
# $(tput setaf 1)!!! YOUR MYSQL-ROOT-PASSWORD: $MYSQL_ROOT_PASS !!!$(tput sgr0)
# Be sure to safe it on a safe place
# $(tput setaf 1)CentOS users have to restart their server to apply the changes to SELinux!$(tput sgr0)
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
