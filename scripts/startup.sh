#!/bin/sh

cd /var/www/

echo "Install composer"
composer install -d /var/www/

php /scripts/startup.php

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
