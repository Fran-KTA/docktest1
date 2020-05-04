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
  fi
else
  echo "NOTICE: Config file exists. Continuing..."
fi

apachectl -D FOREGROUND
