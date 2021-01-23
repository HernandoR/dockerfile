FROM php:8.0.1-fpm

# 更换中国源
ADD sources.list /etc/apt/

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    g++ \
    libbz2-dev \
    libc-client-dev \
    libcurl4-gnutls-dev \
    libedit-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libkrb5-dev \
    libldap2-dev \
    libldb-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libpng-dev \
    libpq-dev \
    libsqlite3-dev \
    libssl-dev \
    libreadline-dev \
    libxslt1-dev \
    libzip-dev \
    memcached \
    wget \
    unzip \
    zlib1g-dev \
    libzstd-dev \
    imagemagick \
    git \
    libsodium-dev
# 未做 php8的支持, 需要源码安装
RUN cd ~ && git clone https://github.com/Imagick/imagick.git && cd imagick && phpize && ./configure && make && make install && docker-php-ext-enable imagick
RUN docker-php-ext-install \
    bz2 \
    bcmath \
    exif \
    shmop \
    sockets \
    opcache \
    pdo_pgsql \
    calendar \
    dba \
    mysqli \
    pdo_mysql \
    pgsql \
    soap \
    zend_test \
    intl \
    zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install gd \
    && PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl && docker-php-ext-install imap \
    && pecl install xdebug && docker-php-ext-enable xdebug \
    && pecl install mongodb && docker-php-ext-enable mongodb \
    && pecl install igbinary && docker-php-ext-enable igbinary \
    && pecl install zstd && docker-php-ext-enable zstd \
    && yes | pecl install redis && docker-php-ext-enable redis
RUN docker-php-source delete \
    && apt-get autoremove --purge -y && apt-get autoclean -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*