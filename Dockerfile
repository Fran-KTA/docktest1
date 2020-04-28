FROM debian:10
LABEL maintainer="Fran"

ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
  && apt install apache2 libapache2-mod-php php-gd php-mysql php-xml php-intl php-redis wget ca-certificates -y --no-install-recommends \
  && rm -f /var/www/html/index.html
RUN   wget -O- https://wordpress.org/latest.tar.gz | tar --strip-components=1 -C /var/www/html/ -zxv \
  && rm -rf /var/lib/apt/lists/* 

WORKDIR /var/www/html

COPY php.ini /etc/php/7.3/apache2/php.ini

EXPOSE 80

CMD ["apachectl","-D","FOREGROUND"]
