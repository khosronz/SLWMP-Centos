# SL(A)EMP

SL(A)EMP stands for Secure L(A)EMP.
It support latest versions of Debian (Stretch) and CentOS (7.x).

## Features

- Setup a secure nginx or apache (only on Debian) config
  - Using the strong cipherlist from https://cipherli.st
- Debian only: Choose between Apache OR Nginx
- Secure your host with a Let's Encrypt certificate
- Subdomain support
- Multiple PHP versions (7.0, 7.1, 7.2) running as FPM
- MariaDB databases with random generated passwords
- Install Nextcloud or Wordpress with an optimized configuration for Apache and Nginx
- Redis support (optional, but recommended if you are using Nextcloud)

## Requirements

- OS: Debian 9 (Stretch) or CentOS 7.x, clean install!

## Installation
Important: SL(A)EMP makes use of various open-source software.
Please assure you agree with their license before using it. Any part of SL(A)EMP itself is released under GNU General Public License, Version 3.

```
git clone https://github.com/timscha/SLEMP SLEMP
chmod +x installer.sh add_domain.sh
./installer.sh
```
The setup script will add the following repositories, dependent on your OS:

- NGINX (original repository by the nginx developers)
- PHP
  - Debian: DEB.SURY.ORG https://deb.sury.org/
  - CentOS: Remi's RPM repository (https://rpms.remirepo.net)
- MariaDB (original repository by the MariaDB developers)

After the installer is finished, CentOS user have to restart there system!
Also save your MySQL root password on a secure place! You will see the password at the end of the installation.

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
- fail2ban
- UFW for debian
- Cleanup the script
