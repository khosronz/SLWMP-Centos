0.7.0
=====
Attention:
The next release will include a breaking point.
- The apache user on Debian will be changed to "apache"
Also PHP 7.0 will be removed, when PHP 7.3 becomes RC or GA

== Changes
=====
+ Fail2ban
+ UFW (for Debian)
+ Adding Apache for CentOS
+ Fixing Logrotate for Apache
+ MariaDB 10.3

0.6.3
=====
+ Redis is available again in NC
- If you have any problems please try to reload the NC a few times.
  If this will not work, open a ticket please

0.6.2
=====
+ Removed Redis for now from NC config because of Internal Server error

0.6.1
=====
+ Changed the behaviour of subdomain creation
+ Added password to Redis
+ Other subdomain related fixes

0.6.0
=====
+ Add: Apache support (only on Debian for now)
+ Add: Support for Nextcloud and Wordpress
+ Add: Redis support
+ Add: IPv6-Support
+ Improvement: Using Ciphers from https://cipherli.st/
+ Fix: Path to fpm socket in nginx


0.5.0
=====
+ Added Subdomain support
+ Rewrite most parts of the script
