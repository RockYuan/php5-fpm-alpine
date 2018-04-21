FROM php:5.6.34-fpm-alpine3.4

ENV RABBITMQ_VERSION v0.8.0
ENV PHP_AMQP_VERSION v1.9.3
ENV PHP_REDIS_VERSION 3.1.4
ENV PHP_MONGO_VERSION 1.3.4
ENV PHP_MEMCACHED_VERSION 2.2.0
ENV PHP_SWOOLE_VERSION v2.0.11
# 2.0.12 >= php7
ENV PHP_IMAGICK_VERSION 3.4.3
ENV PHP_XDEBUG_VERSION XDEBUG_2_5_5
# 2.6.0 >= php7

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    pcre-dev \
    make \
    git \
    pkgconf \
    re2c

RUN apk add --no-cache --virtual .persistent-deps \
    # for intl extension
    icu-dev \
    # for mcrypt extension
    libmcrypt-dev \
    # for mongodb
    libssl1.0 \
    # for gd
    libpng \
    freetype \
    freetype-dev \
    libjpeg-turbo \
    libjpeg-turbo-dev \
    # for imagick
    imagemagick \
    # for memcached
    libmemcached-libs \
    zlib

RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        openssl-dev \
        # for gd
        libpng-dev \
        #freetype-dev \
        #libjpeg-dev \
        #libjpeg-turbo-dev \
        # for memcached
        libmemcached-dev \
        zlib-dev \
        cyrus-sasl-dev \
        # for imagick
        imagemagick-dev \
        libtool \
        # for swoole
        linux-headers \
    && docker-php-ext-configure bcmath --enable-bcmath \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure gd \
            --with-freetype-dir=/usr/include/ \
            --with-jpeg-dir=/usr/include/ \
            --with-png-dir=/usr/include/ \
            #--with-gd \
    # 生产环境利用opcache中间代码复用加速
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install opcache \
    && docker-php-ext-install \
        bcmath \
        intl \
        mcrypt \
        pdo_mysql \
        gd \
        zip \
    && git clone --branch ${RABBITMQ_VERSION} https://github.com/alanxz/rabbitmq-c.git /tmp/rabbitmq \
        && cd /tmp/rabbitmq \
        && mkdir build && cd build \
        && cmake .. \
        && cmake --build . --target install \
        # workaround for linking issue
        && cp -r /usr/local/lib64/* /usr/lib/ \
    && git clone --branch ${PHP_AMQP_VERSION} https://github.com/pdezwart/php-amqp.git /tmp/php-amqp \
        && cd /tmp/php-amqp \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
        && make test \
    && git clone --branch ${PHP_REDIS_VERSION} https://github.com/phpredis/phpredis /tmp/phpredis \
        && cd /tmp/phpredis \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
        && make test \
    && git clone --branch ${PHP_MONGO_VERSION} https://github.com/mongodb/mongo-php-driver /tmp/php-mongo \
        && cd /tmp/php-mongo \
        && git submodule sync && git submodule update --init \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
        && make test \
    && git clone --branch ${PHP_MEMCACHED_VERSION} https://github.com/php-memcached-dev/php-memcached.git /tmp/php-memcached \
        && docker-php-ext-configure /tmp/php-memcached \
        && docker-php-ext-install /tmp/php-memcached \
        # && cd /tmp/php-memcached \
        # && phpize  \
        # && ./configure  \
        # && make  \
        # && make install \
        # && make test \
    # 安装imagick
    # && pecl install imagick-${PHP_IMAGICK_VERSION} \
    # && docker-php-ext-enable imagick \
    && git clone --branch ${PHP_IMAGICK_VERSION} https://github.com/mkoppanen/imagick.git /tmp/php-imagick \
        && docker-php-ext-configure /tmp/php-imagick \
        && docker-php-ext-install /tmp/php-imagick \
    # 安装swoole
    # && pecl install swoole-${PHP_SWOOLE_VERSION} \
    # && docker-php-ext-enable swoole \
    && git clone --branch ${PHP_SWOOLE_VERSION} https://github.com/swoole/swoole-src.git /tmp/php-swoole \
        && docker-php-ext-configure /tmp/php-swoole \
        && docker-php-ext-install /tmp/php-swoole \
    # 开发环境启用xdebug
    # && pecl install xdebug-${PHP_XDEBUG_VERSION} \
    # && docker-php-ext-enable xdebug \
    && git clone --branch ${PHP_XDEBUG_VERSION} https://github.com/xdebug/xdebug.git /tmp/php-xdebug \
        && docker-php-ext-configure /tmp/php-xdebug \
        && docker-php-ext-install /tmp/php-xdebug \
    && apk del .build-deps \
    && rm -rf /tmp/* \
    && rm -rf /var/www \
    && mkdir -p /var/www

# Possible values for ext-name:
# bcmath bz2 calendar ctype curl dba dom enchant exif fileinfo filter ftp gd gettext gmp hash iconv imap interbase intl
# json ldap mbstring mcrypt mssql mysql mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci
# pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline recode reflection session shmop simplexml snmp soap
# sockets spl standard sybase_ct sysvmsg sysvsem sysvshm tidy tokenizer wddx xml xmlreader xmlrpc xmlwriter xsl zip 

# Copy configuration
COPY config/fpm/php-fpm.conf /usr/local/etc/
COPY config/fpm/pool.d /usr/local/etc/pool.d
COPY config/php.ini $PHP_INI_DIR
COPY config/amqp.ini $PHP_INI_DIR/conf.d/
COPY config/redis.ini $PHP_INI_DIR/conf.d/
COPY config/mongodb.ini $PHP_INI_DIR/conf.d/
# 生产环境利用opcache中间代码复用加速
COPY config/opcache.ini $PHP_INI_DIR/conf.d/
# 开发环境启用xdebug
COPY config/xdebug.ini $PHP_INI_DIR/conf.d/

# install composer
RUN curl --tlsv1 -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/bin
ENV PATH /root/.composer/vendor/bin:$PATH

WORKDIR /var/www
