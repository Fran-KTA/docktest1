#!/bin/bash

if [ ! -f /var/www/html/wp-config.php ]; then
  if [ -z "$MYSQL_USER" -o -z "$MYSQL_PASSWORD" -o -z "MYSQL_HOST" -o -z "$MYSQL_DATABASE" ]; then
    echo "NOTICE: No MYSQL varibles set and no config file exists. Continuing with installation...";
  else
    {
      echo s/database_name_here/${MYSQL_DATABASE}/g;
      echo s/username_here/${MYSQL_USER}/g;
      echo s/password_here/${MYSQL_PASSWORD}/g;
      echo s/DB_HOST\', \'localhost/DB_HOST\', \'${MYSQL_HOST}/g;
      echo s/DB_NAME\', \'\'/DB_NAME\', \'${MYSQL_DATABASE}\'/;
    } | sed -f - /var/www/html/wp-config-sample.php > /var/www/html/wp-config.php;
    {
      echo "define('WP_HOME','${HTTP_PROTO:-http}://${WORDPRESS_HOST:-localhost}');";
      echo "define('WP_SITEURL','${HTTP_PROTO:-http}://${WORDPRESS_HOST:-localhost}');";
    } >> /var/www/html/wp-config.php
  fi
else
  echo "NOTICE: Config file exists. Continuing with HOST FQDN reconfig..."
  {
    echo s/WP_HOME\',\'.*\'/WP_HOME\',\'${HTTP_PROTO:-http}://${WORDPRESS_HOST:-localhost}\'/g;
    echo s/WP_SITEURL\',\'.*\'/WP_SITEURL\',\'${HTTP_PROTO:-http}://${WORDPRESS_HOST:-localhost}\'/g;
  } | sed -f - -i /var/www/html/wp-config.php
fi

if [ ! -z "${REDIS_HOST}" ]; then
  echo "NOTICE: Setting up Redis session handler..."
  {
    echo s/^session.save_handler = files/session.save_handler = redis\\n session.save_path = "tcp:\/\/${REDIS_HOST:-redis}:${REDIS_PORT:-6379}\/?auth=${REDIS_PASSWORD:-}"/g;
  } | sed -f - -i /etc/php/7.3/apache2/php.ini
fi

apachectl -D FOREGROUND
