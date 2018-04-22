#!/bin/bash

# Copyright original script by Rimuhosting.com
# Copyright 2017 Tim Scharner (https://scharner.me)
# Version 0.5.0-dev

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

servicesCheck(){
ps cax | grep $1 > /dev/null
if [ $? -eq 0 ]; then
  return 1
else
  return 0
fi
}

choice () {
    local choice=$1
    if [[ ${php_opts[choice]} ]] # toggle
    then
        php_opts[choice]=
    else
        php_opts[choice]=[X]
    fi
}

install_mariadb(){

	if servicesCheck "mysql"; then
                MYSQL_ROOT_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c14)

                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  apt install expect software-properties-common dirmngr -y > /dev/null
                  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
                  add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.2/debian stretch main'

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
cat >/etc/yum.repos.d/MariaDB.repo <<EOL
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOL

                  rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
                  yum update -y && yum install MariaDB-server MariaDB-client expect -y > /dev/null

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

                  yum remove expect -y > /dev/null
                  return 0
                fi
  else
    return 1
	fi
}

install_nginx() {
    if servicesCheck "nginx"; then
                if [ $DISTRO = "debian" ]; then
                  # Add sources for debian from nginx website, import there key and install nginx
                  echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" > /etc/apt/sources.list.d/nginx.list
                  echo "deb-src http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" >> /etc/apt/sources.list.d/nginx.list
                  cd /tmp && wget http://nginx.org/keys/nginx_signing.key > /dev/null && apt-key add nginx_signing.key > /dev/null
                  rm /tmp/nginx_signing.key
                  apt-update > /dev/null
                  apt-get install nginx -y > /dev/null
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
                  yum update -y && yum install nginx -y > /dev/null
                  rm -f /tmp/nginx_signing.key
                fi
                return 0
    else
      return 1
    fi

}

initialize_nginx() {
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
}

install_phpfpm() {
#if servicesCheck "php-fpm"; then
                if [ $DISTRO = "debian" ]; then
                  #We will using sources from https://deb.sury.org/
                  apt-get install apt-transport-https lsb-release ca-certificates -y > /dev/null
                  cd /tmp && wget --quiet /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg > /dev/null
                  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
                  rm /tmp/php.gpg
                  apt-get update > /dev/null
                  for opt in "${!php_opts[@]}"
                  do
                    if [[ ${php_opts[opt]} ]];then
                          if (($opt=="1")); then
                            apt-get -q install php7.0-fpm php7.0-mysql php7.0-gd php7.0-cli php7.0-curl php7.0-mbstring php7.0-posix php7.0-mcrypt php7.0-xml php7.0-xmlrpc php7.0-intl php7.0-mcrypt php7.0-imagick php7.0-xml php7.0-zip -y > /dev/null
                            systemctl start php7.0-fpm
                            systemctl enable php7.0-fpm
                            printf "  - PHP 7.0 installed [X]"
                          fi
                          if (($opt=="2")); then
                            apt-get -q install php7.1-fpm php7.1-mysql php7.1-gd php7.1-cli php7.1-curl php7.1-mbstring php7.1-posix php7.1-mcrypt php7.1-xml php7.1-xmlrpc php7.1-intl php7.1-mcrypt php7.1-imagick php7.1-xml php7.1-zip -y > /dev/null
                            systemctl start php7.1-fpm
                            systemctl enable php7.1-fpm
                            printf "  - PHP 7.1 installed [X]"
                          fi
                          if (($opt=="3")); then
                            apt-get -q install php7.2-fpm php7.2-mysql php7.2-gd php7.2-cli php7.2-curl php7.2-mbstring php7.2-posix php7.2-xml php7.2-xmlrpc php7.2-intl php7.2-imagick php7.2-xml php7.2-zip -y > /dev/null
                            systemctl start php7.2-fpm
                            systemctl enable php7.2-fpm
                            printf "  - PHP 7.2 installed [X]"
                          fi
                    fi
                  done
                  return 0
                fi
                if [ $DISTRO = "centos" ]; then
                  # Using Remis Repo https://rpms.remirepo.net/
                  yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y > /dev/null
                  yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y > /dev/null
                  yum update -y && yum install yum-utils -y > /dev/null
                  for opt in "${!php_opts[@]}"
                  do
                    if [[ ${php_opts[opt]} ]];then
                          if (($opt=="1")); then
                            yum install php70-php-fpm php70-php-mysql php70-php-gd php70-php-cli php70-php-curl php70-php-mbstring php70-php-posix php70-php-mcrypt php70-php-xml php70-php-xmlrpc php70-php-intl php70-php-mcrypt php70-php-imagick php70-php-xml php70-php-zip -y > /dev/null
                            systemctl start php70-php-fpm
                            systemctl enable php70-php-fpm
                            printf "  - PHP 7.0 installed [X]"
                          fi
                          if (($opt=="2")); then
                            apt install php7.1-fpm php7.1-mysql php7.1-gd php7.1-cli php7.1-curl php7.1-mbstring php7.1-posix php7.1-mcrypt php7.1-xml php7.1-xmlrpc php7.1-intl php7.1-mcrypt php7.1-imagick php7.1-xml php7.1-zip -y > /dev/null
                            systemctl start php7.1-fpm
                            systemctl enable php7.1-fpm
                            printf "  - PHP 7.1 installed [X]"
                          fi
                          if (($opt=="3")); then
                            yum install php72-php-fpm php72-php-mysql php72-php-gd php72-php-cli php72-php-curl php72-php-mbstring php72-php-posix php72-php-xml php72-php-xmlrpc php72-php-intl php72-php-imagick php72-php-xml php72-php-zip -y > /dev/null
                            systemctl start php72-php-fpm
                            systemctl enable php72-php-fpm
                            printf "  - PHP 7.2 installed [X]"
                          fi
                    fi
                  done

                  return 0
                fi
#else
 # return 1
#fi
}

install_letsencrypt() {
  #curl https://get.acme.sh | sh
  return 0
}

configure_centos() {
  firewall-cmd --permanent --zone=public --add-service=http
  firewall-cmd --permanent --zone=public --add-service=https
  firewall-cmd --reload
  printf "  - Adding firewalld rules for nginx [X]"
  sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
  printf "  - Disabled SELINUX [X]"
  printf "  $(tput setaf 1)!!! A reboot is requiered! $(tput sgr0)"
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
 -p     Select which PHP-version do you want to installation
 Valid options are "php70", "php71", "php72" or "all"
 -h			this Help
"
USAGE
}

echo <<EOF "
$(basename $0) will attempt to install SLEMP.
This script is provided as it is, no warraties implied.
"
EOF

read -p "Do you want to start the installation? y/n" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  PS3='Please select your PHP versions: '
  while :
  do
      clear
      options=("PHP 7.0 ${php_opts[1]}" "PHP 7.1 ${php_opts[2]}" "PHP 7.2 ${php_opts[3]}" "Done")
      select opt in "${options[@]}"
      do
          case $opt in
              "PHP 7.0 ${php_opts[1]}")
                  choice 1
                  break
                  ;;
              "PHP 7.1 ${php_opts[2]}")
                  choice 2
                  break
                  ;;
              "PHP 7.2 ${php_opts[3]}")
                  choice 3
                  break
                  ;;
              "Done")
                  break 2
                  ;;
              *) printf '%s\n' 'invalid option';;
          esac
      done
  done
    clear
    printf "######################################\nInstallation of SLEMP will start now\n######################################\n"
    printf "nginx installation . . . "
    if install_nginx $1; then echo "[X]"; else echo "Failed..."; fi
    printf "\nMariaDB installation . . . "
    #if install_mariadb $1; then echo "[X]"; else echo "Failed..."; fi
    printf "\nPHP installation . . . "
    if install_phpfpm $1; then echo "[X]"; else echo "Failed..."; fi
    #install_letsencrypt

    if [ $DISTRO = "centos" ]; then
      printf "Configure some CentOS related things..."
      configure_centos
    fi
    [ $? -ne "0" ] && exit 1
fi

echo <<EOF "
# $(tput setaf 1)!!! YOUR MYSQL-ROOT-PASSWORD: $MYSQL_ROOT_PASS !!!$(tput sgr0)
"
EOF


exit 0
