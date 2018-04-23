#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
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

initialize_os() {
  if [ $DISTRO = "debian" ]; then
    # MariaDB
    apt-get -qq install curl wget software-properties-common dirmngr -y < /dev/null > /dev/null
    DEBIAN_FRONTEND=noninteractive apt-get -qq update < /dev/null > /dev/null

    DEBIAN_FRONTEND=noninteractive apt-key adv --recv-keys -qq --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8 < /dev/null > /dev/null
    add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.2/debian stretch main'

    echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" >> /etc/apt/sources.list.d/nginx.list
    curl -O -s https://nginx.org/keys/nginx_signing.key && apt-key -qq add ./nginx_signing.key < /dev/null > /dev/null
    rm ./nginx_signing.key

    apt-get -qq update

    #We will using sources from https://deb.sury.org/
    DEBIAN_FRONTEND=noninteractive apt-get -qq install apt-transport-https lsb-release ca-certificates < /dev/null > /dev/null
    cd /tmp && wget --quiet -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

    apt-get -qq update

  fi

  if [ $DISTRO = "centos" ]; then
    yum -q update -y
    yum -q install curl wget -y
    cat >/etc/yum.repos.d/MariaDB.repo <<EOL
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOL
    rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB > /dev/null
    rpm --import http://nginx.org/keys/nginx_signing.key> /dev/null
cat >/etc/yum.repos.d/nginx.repo <<EOL
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOL
    yum -q update -y
    yum -q install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
    yum -q install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
    yum -q update -y && yum -q install yum-utils -y > /dev/null
  fi
}

install_nginx() {
  if servicesCheck "nginx"; then
    if [ $DISTRO = "debian" ]; then
      DEBIAN_FRONTEND=noninteractive apt-get -qq install nginx -y < /dev/null > /dev/null
    fi
    if [ $DISTRO = "centos" ]; then
      yum update -y && yum install nginx -y > /dev/null
      rm -f /tmp/nginx_signing.key
    fi
    return 0
  else
    return 1
  fi
}

install_mariadb(){
  if servicesCheck "mysql"; then

    if [ $DISTRO = "debian" ]; then
      DEBIAN_FRONTEND=noninteractive apt-get -qq install mariadb-server mariadb-client -y < /dev/null > /dev/null
      systemctl -q enable mariadb
      systemctl -q start mariadb

    fi
    if [ $DISTRO = "centos" ]; then
      yum -q install MariaDB-server MariaDB-client -y > /dev/null

      systemctl -q enable mariadb
      systemctl -q start mariadb

      return 0
    fi
  else
    return 1
  fi
}

install_phpfpm() {
if servicesCheck "php-fpm"; then
  if [ $DISTRO = "debian" ]; then
    for opt in "${!php_opts[@]}"
      do
        if [[ ${php_opts[opt]} ]];then
          if (($opt=="1")); then
            DEBIAN_FRONTEND=noninteractive apt-get -qq install php7.0-fpm php7.0-mysql php7.0-gd php7.0-cli php7.0-curl php7.0-mbstring php7.0-posix php7.0-mcrypt php7.0-xml php7.0-xmlrpc php7.0-intl php7.0-mcrypt php7.0-imagick php7.0-xml php7.0-zip -y < /dev/null > /dev/null
            systemctl -q start php7.0-fpm
            systemctl -q enable php7.0-fpm
            printf "  - PHP 7.0 installed [X]"
          fi
          if (($opt=="2")); then
            DEBIAN_FRONTEND=noninteractive apt-get -qq install php7.1-fpm php7.1-mysql php7.1-gd php7.1-cli php7.1-curl php7.1-mbstring php7.1-posix php7.1-mcrypt php7.1-xml php7.1-xmlrpc php7.1-intl php7.1-mcrypt php7.1-imagick php7.1-xml php7.1-zip -y < /dev/null > /dev/null
            systemctl -q start php7.1-fpm
            systemctl -q enable php7.1-fpm
            printf "  - PHP 7.1 installed [X]"
          fi
          if (($opt=="3")); then
            DEBIAN_FRONTEND=noninteractive apt-get -qq install php7.2-fpm php7.2-mysql php7.2-gd php7.2-cli php7.2-curl php7.2-mbstring php7.2-posix php7.2-xml php7.2-xmlrpc php7.2-intl php7.2-imagick php7.2-xml php7.2-zip -y < /dev/null > /dev/null
            systemctl -q start php7.2-fpm
            systemctl -q enable php7.2-fpm
            printf "  - PHP 7.2 installed [X]"
          fi
        fi
      done
      return 0
    fi
    if [ $DISTRO = "centos" ]; then
      for opt in "${!php_opts[@]}"
      do
        if [[ ${php_opts[opt]} ]];then
          if (($opt=="1")); then
            yum -q install php70-php-fpm php70-php-mysql php70-php-gd php70-php-cli php70-php-curl php70-php-mbstring php70-php-posix php70-php-mcrypt php70-php-xml php70-php-xmlrpc php70-php-intl php70-php-mcrypt php70-php-imagick php70-php-xml php70-php-zip -y > /dev/null
            systemctl -q start php70-php-fpm
            systemctl -q enable php70-php-fpm
            printf "  - PHP 7.0 installed [X]"
          fi
          if (($opt=="2")); then
            yum -q install php71-php-fpm php71-php-mysql php71-php-gd php71-php-cli php71-php-curl php71-php-mbstring php71-php-posix php71-php-mcrypt php71-php-xml php71-php-xmlrpc php71-php-intl php71-php-mcrypt php71-php-imagick php71-php-xml php71-php-zip -y
            systemctl -q start php7.1-fpm
            systemctl -q enable php7.1-fpm
            printf "  - PHP 7.1 installed [X]"
          fi
          if (($opt=="3")); then
            yum -q install php72-php-fpm php72-php-mysql php72-php-gd php72-php-cli php72-php-curl php72-php-mbstring php72-php-posix php72-php-xml php72-php-xmlrpc php72-php-intl php72-php-imagick php72-php-xml php72-php-zip -y > /dev/null
            systemctl -q start php72-php-fpm
            systemctl -q enable php72-php-fpm
            printf "  - PHP 7.2 installed [X]"
          fi
        fi
      done
      return 0
    fi
  else
    return 1
  fi
}

install_letsencrypt() {
  #curl https://get.acme.sh | sh
  #/root/.acme.sh/account.conf
  #CERT_HOME="/etc/ssl/private"
  return 0
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

  systemctl -q start nginx
  systemctl -q enable nginx
}

initialize_mariadb() {
  MYSQL_ROOT_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c14)

  if ! is_mysql_command_available; then
    echo "The MariaDB client is not installed."
    exit 1
  fi

  if is_mysql_root_password_set; then
    echo "Database root password already set"
    exit 1
  fi

mysql --user=root <<EOF
  UPDATE mysql.user SET Password=PASSWORD('${MYSQL_ROOT_PASS}') WHERE User='root';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
EOF
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

echo <<EOF "
$(basename $0) will attempt to install SLEMP.
This script is provided as it is, no warraties implied.
"
EOF

read -p "Do you want to start the installation? y/n" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Before we start the installation and further configuration, the script will add some repositories to your system. This will take a few seconds."
  read -p "Press ENTER to confirm"
  initialize_os

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
  printf "Installing nginx . . . "
  if install_nginx $1; then echo "[X]"; else echo "Failed..."; fi
  printf "\nConfiguring nginx . . ."
  if initialize_nginx $1; then echo "[X]"; else echo "Failed..."; fi
  printf "\nInstalling MariaDB . . . "
  if install_mariadb $1; then echo "[X]"; else echo "Failed..."; fi
  printf "\nInstalling PHP . . . "
  if install_phpfpm $1; then echo ""; else echo "Failed..."; fi
  #install_letsencrypt

  if [ $DISTRO = "centos" ]; then
    printf "Configure CentOS . . ."
    configure_centos
  fi
  [ $? -ne "0" ] && exit 1
fi

echo <<EOF "
# $(tput setaf 1)!!! YOUR MYSQL-ROOT-PASSWORD: $MYSQL_ROOT_PASS !!!$(tput sgr0)
"
EOF


exit 0
