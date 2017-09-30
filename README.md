# SLEMP

SLEMP stands for Secure LEMP.

It will support latest versions of Debian (Stretch) and CentOS (7.x). Successfully tested on both systems.

Why all the effort? Because I want to learn! Yes, at this moment the script is really stupid, but I hope that will change soon. :-)

## What it does?

- Install nginx and MariaDB packages from original developers
- Install PHP 7.1 packages from http://deb.sury.org/ (Debian) and Remi's RPM repository (http://rpms.famillecollet.com/) (CentOS)
- Add an user for the vhost, add an PHP-FPM pool
- Requested a certifcate from Let's Encrypt using certbot
- Add a Nginx and Logrotation config, compatible with Wordpress
- Add an MySQL database and user
- If you use the -s paramter, wordpress will be downloaded and the configuration will be prepared.

## Requirements

- OS: Debian 9 (Stretch) or CentOS 7.x
- Clean minimal installation (git and wget necessary)
- Important: NO webserver, MySQL/MariaDB or PHP-FPM may be installed!

## Installation

```
Be sure to be root!
cd /root && wget https://github.com/timscha/SLEMP/archive/0.4.0.zip
unzip 0.4.0.zip && cd SLEMP-0.4.0 && chmod +x add_vhost.sh install_slemp.sh

./install_slemp.sh -p (php70/php71/php72/all)
```

Optional: If you want to select the PHP-version add the -p paramter.
Default version is PHP 7.1, you can choose between "php70", "php71", "php72" and "all"

Please notice: At this time, PHP 7.2 is only available as RC. Do not use it in productive enviroment!

Please safe your MySQL root password on a safe place! This will show you at the end of the installation!

## Usage

After installation you can add an Vhost with

```
./add_vhost.sh -d <YOUR_DOMAINNAME> -m <Your_MariaDB_Root_Password> -p php70/php71 -s wordpress
```

"-s wordpress" is optional
"-p php which you want to use on the vhost"

Please NOT adding WWW before your domain! The script will do this for you!

## To Dos

- Subdomain support
