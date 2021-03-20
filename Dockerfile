FROM alpine:latest AS builder

RUN apk add --no-cache \
        ca-certificates \
        curl \
        tar \
        xz \
        openssl \
    && c_rehash

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /var/www/html/ \
    && curl -SL https://github.com/RSS-Bridge/rss-bridge/archive/master.tar.gz \
    | tar -xzC /var/www/html/ --strip-components=1


FROM php:7.4-fpm-alpine

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

ENV MEMCACHED_DEPS zlib-dev libmemcached-dev cyrus-sasl-dev
RUN apk add --no-cache --update libmemcached-libs zlib
RUN set -xe \
    && apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache --update --virtual .memcached-deps $MEMCACHED_DEPS \
    && pecl install memcached \
    && docker-php-ext-enable igbinary memcached \
    && rm -rf /usr/share/php7 \
    && rm -rf /tmp/* \
    && apk del .memcached-deps .phpize-deps

COPY --chown=www-data --from=builder /var/www/html/ .
