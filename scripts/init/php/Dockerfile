FROM php:7.4-fpm
#RUN sed -i 's/9000/9001/' /usr/local/etc/php-fpm.d/zz-docker.conf
RUN apt-get update && apt-get install -y \
	libzip-dev \
	zip \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install fileinfo \
    && echo '' | pecl install redis \
    && docker-php-ext-enable redis
