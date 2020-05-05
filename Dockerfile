FROM debian:10-slim
LABEL maintainer="Fran ( https://github.com/Fran-KTA )"

ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
  && apt install apache2 libapache2-mod-php php-gd php-mysql php-xml php-intl php-redis wget ca-certificates -y --no-install-recommends \
  && sed -ri ' \
     s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
     s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
     ' /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-available/000-default.conf /etc/apache2/apache2.conf \
  && rm -f /var/www/html/index.html
RUN   wget -O- https://wordpress.org/latest.tar.gz | tar --strip-components=1 -C /var/www/html/ -zxv \
  && rm -rf /var/lib/apt/lists/* 

COPY entrypoint.sh /entrypoint.sh

WORKDIR /var/www/html

COPY sess_test.php .

EXPOSE 80

ENTRYPOINT /entrypoint.sh
#CMD ["apachectl","-D","FOREGROUND"]
