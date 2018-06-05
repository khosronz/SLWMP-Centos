#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
# Version 0.6.0

if [[ $EUID -ne 0 ]]; then
   echo "$(tput setaf 1)This script must be run as root$(tput sgr0)" 1>&2
   exit 1
fi

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
    if [[ ${php_opts[choice]} ]]
    then
        php_opts[choice]=
    else
        php_opts[choice]=[X]
    fi
}

initialize_os() {
  if [ $DISTRO = "debian" ]; then
	DEBIAN_FRONTEND=noninteractive apt-get -qq update >> /tmp/slemp_install.txt 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get -qq install apt-transport-https lsb-release ca-certificates curl wget software-properties-common dirmngr -y >> /tmp/slemp_install.txt 2>&1

    DEBIAN_FRONTEND=noninteractive apt-key adv --recv-keys -qq --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8 >> /tmp/slemp_install.txt 2>&1
    add-apt-repository -y 'deb [arch=amd64,i386,ppc64el] http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.2/debian stretch main' >> /tmp/slemp_install.txt 2>&1

    echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src http://nginx.org/packages/mainline/debian/ $(lsb_release -c -s) nginx" >> /etc/apt/sources.list.d/nginx.list
    curl -O -s https://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key >> /tmp/slemp_install.txt 2>&1
    rm nginx_signing.key

    apt-get -qq update

    cd /tmp && wget --quiet -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

    apt-get -qq update >> /tmp/slemp_install.txt 2>&1

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
    yum -q update -y && yum -q install firewalld yum-utils -y >> /tmp/slemp_install.txt 2>&1

	  systemctl -q enable firewalld
    systemctl -q start firewalld
  fi
}

install_apache() {
  if servicesCheck "apache2"; then
    if [ $DISTRO = "debian" ]; then
      DEBIAN_FRONTEND=noninteractive apt-get -qq install apache2 -y >> /tmp/slemp_install.txt 2>&1
    fi
    return 0
  else
    return 1
  fi
}

install_nginx() {
  if servicesCheck "nginx"; then
    if [ $DISTRO = "debian" ]; then
      DEBIAN_FRONTEND=noninteractive apt-get -qq install nginx -y >> /tmp/slemp_install.txt 2>&1
    fi
    if [ $DISTRO = "centos" ]; then
      yum -q install nginx -y >> /tmp/slemp_install.txt 2>&1
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
      DEBIAN_FRONTEND=noninteractive apt-get -qq install mariadb-server mariadb-client -y >> /tmp/slemp_install.txt 2>&1
      systemctl -q enable mariadb
      systemctl -q start mariadb

    fi
    if [ $DISTRO = "centos" ]; then
      yum -q install MariaDB-server MariaDB-client -y >> /tmp/slemp_install.txt 2>&1
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
            DEBIAN_FRONTEND=noninteractive apt-get -qq install php7.0-fpm php7.0-mysql php7.0-gd php7.0-cli php7.0-curl php7.0-mbstring php7.0-posix php7.0-mcrypt php7.0-xml php7.0-xmlrpc php7.0-intl php7.0-mcrypt php7.0-imagick php7.0-xml php7.0-zip php7.0-apcu php7.0-opcache -y >> /tmp/slemp_install.txt 2>&1
            systemctl -q start php7.0-fpm
            systemctl -q enable php7.0-fpm
            printf "\n - PHP 7.0 installed [X]"
          fi
          if (($opt=="2")); then
            DEBIAN_FRONTEND=noninteractive apt-get -qq install php7.1-fpm php7.1-mysql php7.1-gd php7.1-cli php7.1-curl php7.1-mbstring php7.1-posix php7.1-mcrypt php7.1-xml php7.1-xmlrpc php7.1-intl php7.1-mcrypt php7.1-imagick php7.1-xml php7.1-zip php7.1-apcu php7.1-opcache -y >> /tmp/slemp_install.txt 2>&1
            systemctl -q start php7.1-fpm
            systemctl -q enable php7.1-fpm
            printf "\n - PHP 7.1 installed [X]"
          fi
          if (($opt=="3")); then
            DEBIAN_FRONTEND=noninteractive apt-get -qq install php7.2-fpm php7.2-mysql php7.2-gd php7.2-cli php7.2-curl php7.2-mbstring php7.2-posix php7.2-xml php7.2-xmlrpc php7.2-intl php7.2-imagick php7.2-xml php7.2-zip php7.2-apcu php7.2-opcache -y >> /tmp/slemp_install.txt 2>&1
            systemctl -q start php7.2-fpm
            systemctl -q enable php7.2-fpm
            printf "\n- PHP 7.2 installed [X]"
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
            yum -q install php70-php-fpm php70-php-mysql php70-php-gd php70-php-cli php70-php-curl php70-php-mbstring php70-php-posix php70-php-mcrypt php70-php-xml php70-php-xmlrpc php70-php-intl php70-php-mcrypt php70-php-imagick php70-php-xml php70-php-zip php70-php-apcu php70-php-opcache -y >> /tmp/slemp_install.txt 2>&1
            systemctl -q start php70-php-fpm
            systemctl -q enable php70-php-fpm
            printf "\n- PHP 7.0 installed [X]"
          fi
          if (($opt=="2")); then
            yum -q install php71-php-fpm php71-php-mysql php71-php-gd php71-php-cli php71-php-curl php71-php-mbstring php71-php-posix php71-php-mcrypt php71-php-xml php71-php-xmlrpc php71-php-intl php71-php-mcrypt php71-php-imagick php71-php-xml php71-php-zip php71-php-apcu php71-php-opcache -y >> /tmp/slemp_install.txt 2>&1
            systemctl -q start php71-php-fpm
            systemctl -q enable php71-php-fpm
            printf "\n- PHP 7.1 installed [X]"
          fi
          if (($opt=="3")); then
            yum -q install php72-php-fpm php72-php-mysql php72-php-gd php72-php-cli php72-php-curl php72-php-mbstring php72-php-posix php72-php-xml php72-php-xmlrpc php72-php-intl php72-php-imagick php72-php-xml php72-php-zip php72-php-apcu php72-php-opcache -y >> /tmp/slemp_install.txt 2>&1
            systemctl -q start php72-php-fpm
            systemctl -q enable php72-php-fpm
            printf "\n- PHP 7.2 installed [X]"
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
  if [ $DISTRO = "debian" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get -qq install certbot -y >> /tmp/slemp_install.txt 2>&1
  fi
  if [ $DISTRO = "centos" ]; then
    yum -q install certbot -y >> /tmp/slemp_install.txt 2>&1
  fi
  if [ $INSTALLING_HTTPD_SERVER = "0" ]; then
    echo "@weekly certbot renew --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" --renew-hook "systemctl reload nginx" --quiet" >> /etc/crontab
  elif [ $INSTALLING_HTTPD_SERVER = "1" ]; then
    echo "@weekly certbot renew --pre-hook "systemctl stop apache2" --post-hook "systemctl start apache2" --renew-hook "systemctl reload apache2" --quiet" >> /etc/crontab
  fi
  return 0
}

install_redis() {
  if servicesCheck "redis"; then
    if [ $DISTRO = "debian" ]; then
      DEBIAN_FRONTEND=noninteractive apt-get -qq install redis-server -y >> /tmp/slemp_install.txt 2>&1
      cp /etc/redis/redis.conf /etc/redis/redis.conf.org
      systemctl -q start redis
    fi
    if [ $DISTRO = "centos" ]; then
      yum -q install redis -y >> /tmp/slemp_install.txt 2>&1
      cp /etc/redis.conf /etc/redis.conf.org
      systemctl -q start redis
    fi
    return 0
  else
    return 1
  fi
}

initialize_apache() {
  if [ ! -d "/var/www" ]; then
    mkdir /var/www
  fi
  a2enmod http2 > /dev/null 2>&1
  a2enmod rewrite > /dev/null 2>&1
  a2enmod headers > /dev/null 2>&1
  a2enmod env > /dev/null 2>&1
  a2enmod dir > /dev/null 2>&1
  a2enmod mime > /dev/null 2>&1
  a2enmod setenvif > /dev/null 2>&1

  systemctl -q enable apache2
  systemctl -q restart apache2
  return 0
}

initialize_nginx() {
  if [ ! -d "/var/www" ]; then
    mkdir /var/www
  fi
  sed -i '/#gzip  on;/a server_tokens off;' /etc/nginx/nginx.conf
  echo "net.core.netdev_max_backlog=4096" >> /etc/sysctl.conf > /dev/null 2>&1
  echo "net.core.somaxconn=4096" >> /etc/sysctl.conf > /dev/null 2>&1
  echo "net.ipv4.tcp_max_syn_backlog=4096" >> /etc/sysctl.conf > /dev/null 2>&1
  sysctl -p

  openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096 > /dev/null 2>&1

  systemctl -q start nginx
  systemctl -q enable nginx
  return 0
}

initialize_php(){
  if [ $DISTRO = "debian" ]; then
cat <<EOF >/etc/php/7.2/mods-available/opcache.ini
# optimizations for nextcloud
opcache.enable=1
opcache.enable_cli=1
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.memory_consumption=128
opcache.save_comments=1
opcache.revalidate_freq=1
EOF
  sed -i "s/max_execution_time = 30/max_execution_time = 900/" /etc/php/7.*/fpm/php.ini
  sed -i "s/max_input_time = 60/max_input_time = 600/" /etc/php/7.*/fpm/php.ini
  sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 500M/" /etc/php/7.*/fpm/php.ini
  sed -i "s/post_max_size = 8M/post_max_size = 550M/" /etc/php/7.*/fpm/php.ini
  fi
  if [ $DISTRO = "centos" ]; then
  sed -i "s/;opcache.enable_cli=0/opcache.enable_cli=1/" /etc/opt/remi/php7*/php.d/10-opcache.ini
  sed -i "s/opcache.max_accelerated_files=4000/opcache.max_accelerated_files=10000/" /etc/opt/remi/php7*/php.d/10-opcache.ini
  sed -i "s/;opcache.save_comments=1/opcache.save_comments=1/" /etc/opt/remi/php7*/php.d/10-opcache.ini
  sed -i "s/;opcache.revalidate_freq=2/opcache.save_comments=1/" /etc/opt/remi/php7*/php.d/10-opcache.ini
  # /etc/opt/remi/php71/php.ini
  fi
  return 0
}

initialize_mariadb() {

MYSQL_ROOT_PASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c14)

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

initialize_redis() {
  REDIS_HASHPW=$(</dev/urandom tr -dc A-Za-z0-9 | head -c14 | sha256sum | tr -d '-')
  echo "vm.overcommit_memory=1" >> /etc/sysctl.conf > /dev/null 2>&1
  sysctl -p

  if [ $DISTRO = "debian" ]; then
    sed -i "s/port 6379/port 0/" /etc/redis/redis.conf
    sed -i s/\#\ unixsocket/\unixsocket/g /etc/redis/redis.conf
    sed -i 's|unixsocket /var/run/redis/redis.sock|unixsocket /var/run/redis.sock|g' /etc/redis/redis.conf
    sed -i "s/unixsocketperm 700/unixsocketperm 770/" /etc/redis/redis.conf
    sed -i "s/# maxclients 10000/maxclients 512/" /etc/redis/redis.conf
    sed -i "s/# requirepass foobared/requirepass $REDIS_HASHPW /" /etc/redis/redis.conf
    systemctl -q enable redis-server
  fi
  if [ $DISTRO = "centos" ]; then
    mkdir /var/run/redis
    chown redis:redis -R /var/run/redis
    sed -i "s/port 6379/port 0/" /etc/redis.conf
    sed -i s/\#\ unixsocket/\unixsocket/g /etc/redis.conf
    sed -i 's|unixsocket /tmp/redis.sock|unixsocket /var/run/redis/redis.sock|g' /etc/redis.conf
    sed -i "s/unixsocketperm 700/unixsocketperm 770/" /etc/redis.conf
    sed -i "s/# maxclients 10000/maxclients 512/" /etc/redis.conf
    sed -i "s/# requirepass foobared/requirepass $REDIS_HASHPW /" /etc/redis.conf
    systemctl -q enable redis
  fi
    systemctl -q restart redis
  return 0
}

configure_centos() {
  firewall-cmd --permanent --zone=public --add-service=http > /dev/null 2>&1
  firewall-cmd --permanent --zone=public --add-service=https > /dev/null 2>&1
  firewall-cmd --reload > /dev/null 2>&1
  printf "\n- Adding firewalld rules for nginx [X]"
  sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
  printf "\n- Disabled SELINUX [X]\n"
  return 0
}

echo <<EOF "
$(basename $0) will attempt to install SLEMP.

-------------------------------------------------------------------------------
For Let's Encrypt, please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf.
With using this script you agree in order to register with the ACME server at
https://acme-v01.api.letsencrypt.org/directory
-------------------------------------------------------------------------------

This script is provided as it is, no warraties implied.
"
EOF

read -p "Do you want to start the installation? y/n " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Before we start the installation and further configuration, the script will add some repositories and dependencies to your system. This will take a few seconds."
  read -p "Press ENTER to confirm"
  initialize_os
  clear
  if [ $DISTRO = "debian" ]; then
    PS3='Which webserver do you want to install? '
    options=("NGINX" "Apache")
    select opt in "${options[@]}"
    do
        case $opt in
            "NGINX")
                INSTALLING_HTTPD_SERVER="0"
                break
                ;;
            "Apache")
                INSTALLING_HTTPD_SERVER="1"
                break
                ;;
            *) echo invalid option;;
        esac
    done
  else
    INSTALLING_HTTPD_SERVER="0"
  fi

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

  read -p "Do you want to install Redis server? (recommended for Nextcloud) [y/n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    INSTALLING_REDIS=1
  else
    INSTALLING_REDIS=0
  fi
  clear
  printf "######################################\nInstallation of SLEMP\n######################################\n"
  if [ $INSTALLING_HTTPD_SERVER = "0" ]; then
    printf "Installing nginx . . . "
    if install_nginx $1; then echo "[X]"; else echo "Failed..."; fi
    printf "\nConfiguring nginx . . . "
    if initialize_nginx $1; then echo "[X]"; else echo "Failed..."; fi
  fi
  if [ $INSTALLING_HTTPD_SERVER = "1" ]; then
    printf "Installing Apache . . . "
    if install_apache $1; then echo "[X]"; else echo "Failed..."; fi
    printf "\nConfiguring Apache . . . "
    if initialize_apache $1; then echo "[X]"; else echo "Failed..."; fi
  fi
  printf "\nInstalling MariaDB . . . "
  if install_mariadb $1; then echo "[X]"; else echo "Failed..."; fi
  printf "\nConfiguring MariaDB . . . "
  if initialize_mariadb $1; then echo "[X]"; else echo "Failed..."; fi
  printf "\nInstalling PHP . . . "
  if install_phpfpm $1; then echo ""; else echo "Failed..."; fi
  printf "\nInstalling Certbot . . . "
  if install_letsencrypt $1; then echo "[X]"; else echo "Failed..."; fi
  if [ $INSTALLING_REDIS = "1" ]; then
    printf "\nInstalling Redis . . . "
    if install_redis $1; then echo "[X]"; else echo "Failed..."; fi
    printf "\nConfiguring Redis . . . "
    if initialize_redis $1; then echo "[X]"; else echo "Failed..."; fi
  fi

  if [ $DISTRO = "centos" ]; then
    printf "\nConfigure CentOS . . ."
    configure_centos
  fi
  [ $? -ne "0" ] && exit 1
fi
echo
echo "$(tput setaf 1)Your MySQL-Root-Password: $MYSQL_ROOT_PASS Please write it down! $(tput sgr0)"
if [ $DISTRO = "centos" ]; then
	echo
	echo "$(tput setaf 1)You have to restart your system now! $(tput sgr0)"
fi
exit 0
