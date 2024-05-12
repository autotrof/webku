ARG BASE_IMAGE_VERSION

FROM php:${BASE_IMAGE_VERSION}-fpm-alpine

RUN mkdir -p /var/www/html/public
RUN echo echo "<?php phpinfo(); ?>" > /var/www/html/public/index.php

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
COPY custom.ini $PHP_INI_DIR/conf.d/custom.ini

RUN apk add nginx

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY ./run-nginx.sh /run-nginx.sh
COPY ./run-php.sh /run-php.sh
COPY ./start.sh /start.sh
RUN chmod +x /run-nginx.sh
RUN chmod +x /run-php.sh
RUN chmod +x /start.sh

RUN apk --no-cache add \
    libpng \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    libzip-dev \
    jpeg-dev \
    freetype-dev \
    unzip \
    libjpeg-turbo-dev \
    autoconf \
    g++ \
    make \
    postgresql-dev \
    icu-dev \
    nano

# Configure the gd library
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install pdo_pgsql
RUN docker-php-ext-install mbstring
# khusus untuk php7.4 kebawah
# RUN docker-php-ext-install tokenizer
RUN docker-php-ext-install xml
RUN docker-php-ext-install ctype
# khusus untuk php7.4 kebawah
# RUN docker-php-ext-install json
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install fileinfo
RUN docker-php-ext-install gd
RUN docker-php-ext-install exif
RUN docker-php-ext-install intl
RUN docker-php-ext-install opcache


RUN apk del \
    libpng-dev \
    jpeg-dev \
    freetype-dev \
    autoconf \
    g++ \
    make

USER root

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD /start.sh