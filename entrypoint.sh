#!/bin/bash

#if [ "${HTTP_PROTO//https/HTTPS}" == "HTTPS" ]; then
if [ "${HTTP_PROTO^^}" == "HTTPS" ]; then
  echo "NOTICE: Wordpress will be configured for sitting behind an HTTPS reverse proxy..."
fi

if [ ! -f /var/www/html/wp-config.php ]; then
  if [ -z "$MYSQL_USER" -o -z "$MYSQL_PASSWORD" -o -z "MYSQL_HOST" -o -z "$MYSQL_DATABASE" ]; then
    echo "NOTICE: No MYSQL varibles set and no config file exists. Continuing with installation...";
  else
    {
      # Forcing SSL for wp-admin and setting $_SERVER['HTTPS'] (always, as those are driven by env var) must be done early in wp-config.php
      echo "s/<?php/<?php\\ndefine('FORCE_SSL_ADMIN','$([ "${HTTP_PROTO^^}" == "HTTPS" ] && echo "true" || echo "false")');\\n\$_SERVER['HTTPS']='$([ "${HTTP_PROTO^^}" == "HTTPS" ] && echo "on" || echo "off")';"/g;

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
    echo s/SSL_ADMIN\',\'.*\'/SSL_ADMIN\',\'$([ "${HTTP_PROTO^^}" == "HTTPS" ] && echo "true" || echo "false")\'/g;
    echo s/HTTPS\']=\'.*\'/HTTPS\'=\'$([ "${HTTP_PROTO^^}" == "HTTPS" ] && echo "on" || echo "off")\'/g;
  } | sed -f - -i /var/www/html/wp-config.php
fi

{ cat <<EOF
/* Attempt MySQL server connection.
   Will retry 3 times in 10 sec intervals. */

\$link = false;
\$counter = 1;

while ( \$link == false && \$counter<=3 ) {
  \$link = mysqli_connect("${MYSQL_HOST}", "${MYSQL_USER}", "${MYSQL_PASSWORD}", "${MYSQL_DATABASE}");
  if(mysqli_connect_errno() == 1044){
    print("ERROR: Database does not exist or user can't access.");
    exit(1);
  }
  sleep(10);
  \$counter++;
}

// Check connection
if(\$link === false){
    print("ERROR: Could not connect. " . mysqli_connect_error());
    exit(1);
}

// Attempt update query execution
\$sql = "UPDATE wp_options SET option_value='${HTTP_PROTO:-http}://${WORDPRESS_HOST:-localhost}' WHERE option_name in ('siteurl','home')";
if(mysqli_query(\$link, \$sql)){
    echo "INFO: Records were updated successfully.";
} else {
    echo "ERROR: Something went wrong with statement: $sql. " . mysqli_error(\$link);
}

// Close connection
mysqli_close(\$link);
EOF
} | php -a

if [ ! -z "${REDIS_HOST}" ]; then
  echo "NOTICE: Setting up Redis session handler..."
  {
    echo s/^session.save_handler = files/session.save_handler = redis\\nsession.save_path = "tcp:\/\/${REDIS_HOST:-redis}:${REDIS_PORT:-6379}\/?auth=${REDIS_PASSWORD:-}"/g;
  } | sed -f - -i /etc/php/7.3/apache2/php.ini
else
  echo "NOTICE: Setting up FILES session handler..."
  {
    echo s/^session.save_handler = redis/session.save_handler = files/g;
    echo /^session.save_path = tcp:.*$/d;
  } | sed -f - -i /etc/php/7.3/apache2/php.ini
fi

apachectl -D FOREGROUND
