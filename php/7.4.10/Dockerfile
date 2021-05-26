FROM nanoninja/php-fpm:7.4.10

# 更换中国源
ADD sources.list /etc/apt/

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    libgmp-dev
RUN docker-php-ext-install gmp && \
    docker-php-ext-install shmop
