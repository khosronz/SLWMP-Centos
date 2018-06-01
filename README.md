# SLEMP

SLEMP stands for Secure LEMP.
It will support latest versions of Debian (Stretch) and CentOS (7.x).

## Features

- Setup a secure nginx config
- Secure your host with a Let's Encrypt certificate
- Subdomain support
- Multiple PHP versions (7.0, 7.1, 7.2) running as FPM
- MariaDB database with generated passwords

## Requirements

- OS: Debian 9 (Stretch) or CentOS 7.x, clean install!

## Installation
```
 curl https://timscha.io/setup_slemp.sh | sudo bash
```
The setup script will add the following repositories, dependent on your OS:

- NGINX (original repository by the nginx developers)
- PHP
  - Debian: DEB.SURY.ORG https://deb.sury.org/
  - CentOS: Remi's RPM repository (https://rpms.remirepo.net)
- MariaDB (original repository by the MariaDB developers)

After the installer is finished, CentOS user have to restart there system!
Also  safe your MySQL root password on a secure place! You will see the password at the end of the installation.

If something goes wrong there is an installer log available at /tmp/slemp_install.txt

## Usage
```
./add_domain.sh
```

The script will guide you through the setup.
Be sure to point your domain to the IP of your server (www and non-www dns record)

You will find the config and files at the following paths:

#### nginx
- /etc/nginx/conf.d/

#### PHP
- CentOS: /etc/opt/remi/php7x/php-fpm.d/
- Debian: /etc/php/7.x/fpm/pool.d/

### Web
- /var/www/YOUR-DOMAIN/

## What's next
- CMS installations (Wordpress and Nextcloud planed)
- Apache
- Maybe Apache + nginx (as proxy)
