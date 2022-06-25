FROM debian:buster

COPY sources.list /etc/apt/
COPY ./script/docker-php-ext-configure /usr/local/bin/
COPY ./script/docker-php-ext-install /usr/local/bin/
COPY ./script/docker-php-ext-enable /usr/local/bin/
COPY ./script/docker-php-install /usr/local/bin/

ENV PHP_SRC_DIR=/usr/src/php
ENV PHP_INI_DIR=/usr/local/etc/php
ENV PHP_INSTALL_DIR=/usr/local/php

ENV PATH=$PATH:$PHP_INSTALL_DIR/bin:$PHP_INSTALL_DIR/bsin

RUN apt update \
    && apt update \
    && apt install -y \
    git \
    pkg-config \
    build-essential \
    autoconf \
    bison \
    re2c \
    libxml2-dev \
    libsqlite3-dev \
    libreadline-dev \
    wget \
    openssl \
    libssl-dev

RUN git clone https://github.com/php/php-src.git $PHP_SRC_DIR \
    && cd $PHP_SRC_DIR \
    # 基于 php-8.1.7
    && git checkout d35e577a1bd0b35b9386cea97cddc73fd98eed6d \
    && chmod +x /usr/local//bin/docker-php-*

# 替换 PHP 源码文件
COPY ./php-src/zend_vm_execute.h $PHP_SRC_DIR/Zend/zend_vm_execute.h

RUN docker-php-install
