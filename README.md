# SLEMP

SLEMP stands for Secure LEMP.

It will support latest versions of Debian (Stretch) and CentOS (7.x)

Right now it's under development and not working!

There are two basic scripts *install_slemp.sh* and *add_vhost.sh*.

[...]

## Requirements

- OS: Debian 9 (Stretch) or CentOS 7.x
- Clean minimal installation (git and wget necessary)
- Important: NO webserver, MySQL/MariaDB or PHP-FPM may be installed!

## Installation

```
git clone https://github.com/timscha/SLEMP.git
cd SLEMP && chmod +x add_vhost.sh install_slemp.sh
./install_slemp.sh
```

## Usage

Coming later

## To Dos

- Switching script to MariaDB instead of using MySQL
- ~~nginx Installation~~
- ~~php-fpm-Installation~~
- ~~vhost-Configuration~~
- ~~Using Let's Encrypt to secure the website~~
- Adding Logrotation
- Open_basedir
- Subdomain support
