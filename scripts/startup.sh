#!/bin/sh

cd /var/www/

echo "Install composer"
composer install -d /var/www/

php /scripts/startup.php

cp /var/www/crons/cron-wp.dist.yaml /var/www/crons/cronjobs.yaml

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
