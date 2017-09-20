# SLEMP

SLEMP stands for Secure LEMP.

It will support latest versions of Debian (Stretch) and CentOS (7.x). Successfully tested on both systems.

Why all the effort? Because I want to learn! Yes, at this moment the script is really stupid, but I hope that will change soon. :-)


## Requirements

- OS: Debian 9 (Stretch) or CentOS 7.x
- Clean minimal installation (git and wget necessary)
- Important: NO webserver, MySQL/MariaDB or PHP-FPM may be installed!

## Installation

```
Be sure to be root!
cd /root && wget https://github.com/timscha/SLEMP/archive/0.3.0.zip
unzip 0.3.0.zip && cd SLEMP-0.3.0 && chmod +x add_vhost.sh install_slemp.sh
./install_slemp.sh
```

Please safe your MySQL root password on a safe place! This will show you at the end of the installation!

## Usage

After installation you can add an Vhost with

```
./add_vhost.sh -d <YOUR_DOMAINNAME> -m <Your_MariaDB_Root_Password> -s wordpress
```

"-s wordpress" is optional

Please NOT adding WWW before your domain! The script will do this for you!

After confirmation the script do the following:

- Add an user for the Vhost, add an PHP-FPM pool
- Requested a certifcate from Let's Encrypt
- Add a Nginx config + Logrotation, compatible with Wordpress
- Add an MySQL database and user
- If you use the -s paramter, wordpress will be downloaded and the configuration will be prepared.

## To Dos

- Subdomain support
