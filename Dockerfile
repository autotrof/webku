ARG BASE_IMAGE_VERSION

FROM php:${BASE_IMAGE_VERSION}-fpm-alpine

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN sed -i "s/user = www-data/user = root/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = root/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

RUN docker-php-ext-install pdo pdo_mysql

RUN mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/5.3.4.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis

RUN apk add --no-cache zip libzip-dev
RUN docker-php-ext-configure zip
RUN docker-php-ext-install zip

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN echo "memory_limit = 2048M\nupload_max_filesize=20M\npost_max_size=20M" > $PHP_INI_DIR/conf.d/custom.ini

COPY ./run-nginx.sh /run-nginx.sh
COPY ./run-php.sh /run-php.sh
COPY ./run.sh /run.sh
RUN chmod +x /run-nginx.sh
RUN chmod +x /run-php.sh
RUN chmod +x /run.sh

RUN apk add nginx

USER root

CMD /run.sh