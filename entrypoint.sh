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
      echo "define('FORCE_SSL_ADMIN', $([ "${HTTP_PROTO^^}" == "HTTPS" ] && echo "true" || echo "false"));";
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

{ cat <<EOF
/* Attempt MySQL server connection. Assuming you are running MySQL
server with default setting (user 'root' with no password) */
\$link = mysqli_connect("${MYSQL_HOST}", "${MYSQL_USER}", "${MYSQL_PASSWORD}", "${MYSQL_DATABASE}");

// Check connection
if(\$link === false){
    die("ERROR: Could not connect. " . mysqli_connect_error());
}

// Attempt update query execution
\$sql = "UPDATE wp_options SET option_value='${HTTP_PROTO:-http}://${WORDPRESS_HOST:-localhost}' WHERE option_name in ('siteurl','host')";
if(mysqli_query(\$link, \$sql)){
    echo "Records were updated successfully.";
} else {
    echo "ERROR: Could not able to execute $sql. " . mysqli_error(\$link);
}

// Close connection
mysqli_close(\$link);
EOF
} | php -a

#if [ "${HTTP_PROTO//https/HTTPS}" == "HTTPS" ]; then
if [ "${HTTP_PROTO^^}" == "HTTPS" ]; then
  cat > /var/www/html/.htaccess <<'EOF'
<IfModule mod_rewrite.c>
 RewriteEngine On
 RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</IfModule>
EOF
else
  rm -f /var/www/html/.htaccess 2>/dev/null
fi

if [ ! -z "${REDIS_HOST}" ]; then
  echo "NOTICE: Setting up Redis session handler..."
  {
    echo s/^session.save_handler = files/session.save_handler = redis\\n session.save_path = "tcp:\/\/${REDIS_HOST:-redis}:${REDIS_PORT:-6379}\/?auth=${REDIS_PASSWORD:-}"/g;
  } | sed -f - -i /etc/php/7.3/apache2/php.ini
fi

apachectl -D FOREGROUND
