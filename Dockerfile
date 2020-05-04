FROM debian:10-slim
LABEL maintainer="Fran ( https://github.com/Fran-KTA )"

ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
  && apt install apache2 libapache2-mod-php php-gd php-mysql php-xml php-intl php-redis wget ca-certificates -y --no-install-recommends \
  && sed -i 's/^session.save_handler = files/session.save_handler = redis\n session.save_path = "tcp:\/\/redis:6379"/g' /etc/php/7.3/apache2/php.ini \
  && rm -f /var/www/html/index.html
RUN   wget -O- https://wordpress.org/latest.tar.gz | tar --strip-components=1 -C /var/www/html/ -zxv \
  && rm -rf /var/lib/apt/lists/* 

#WORKDIR /var/www/html
COPY entrypoint.sh /entrypoint.sh

EXPOSE 80

ENTRYPOINT /entrypoint.sh
#CMD ["apachectl","-D","FOREGROUND"]
