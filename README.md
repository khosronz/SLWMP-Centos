# SLEMP

SLEMP stands for Secure LEMP.

It will support latest versions of Debian (Stretch) and CentOS (7.x)

Why all the effort? Because I want to learn! Yes, at this moment the script is really stupid, but I hope that will change soon. :-)

Tested this with Debian only at the moment, things might be break on CentOS at the moment. It is necessary to configure selinux.

## Requirements

- OS: Debian 9 (Stretch) or CentOS 7.x
- Clean minimal installation (git and wget necessary)
- Important: NO webserver, MySQL/MariaDB or PHP-FPM may be installed!

## Installation

```
Be sure to be root!
cd /root && wget https://github.com/timscha/SLEMP/archive/0.10.zip
unzip 0.10.zip && cd SLEMP-0.10 && chmod +x add_vhost.sh install_slemp.sh
./install_slemp.sh
```

Please safe your MySQL root password on a safe place! This will show you at the end of the installation!

## Usage

After installation you can add an Vhost with "./add_vhost.sh -d <YOUR_DOMAINNAME>" -m <Your MySQL-Root_Password>

Please NOT adding WWW before your domain! After confirmation the script do the following:

- Add an user for the Vhost, add an PHP-FPM pool
- Requested a certifcate from Let's Encrypt
- Add a Nginx config, compatible with Wordpress
- Add an MySQL database and user

## To Dos

- Adding Logrotation
- Subdomain support
