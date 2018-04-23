FROM php:5.6-fpm-alpine

# 第三方插件的版本号
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

# 安装需要的插件
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        # for gd extension
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        # for intl extension
        icu-dev \
        # for mcrypt extension
        libmcrypt-dev \
        # for mongodb
        libssl1.0 \
        # for imagick
        imagemagick \
        libtool \
        # for memcached
        libmemcached-dev \
        zlib-dev \
        cyrus-sasl-dev \
        # for swoole
        linux-headers \
        # for ...
        openssl-dev \
    ; \
    \
    docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr; \
    docker-php-ext-install gd mysqli opcache; \
    \
    docker-php-ext-configure bcmath --enable-bcmath; \
    docker-php-ext-configure intl --enable-intl; \
    # docker-php-ext-configure pdo_mysql --with-pdo-mysql; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .phpexts-rundeps $runDeps; \
    apk del .build-deps \
    # 建立默认工作目录
    rm -rf /data \
    mkdir -p /data

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

WORKDIR /data
