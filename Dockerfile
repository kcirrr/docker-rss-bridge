FROM debian:buster-slim AS builder
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update \
    && apt-get install -qq -y --no-install-recommends \
    curl \
    ca-certificates \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/* \
    && c_rehash

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /var/www/html/ \
    && curl -SL https://github.com/RSS-Bridge/rss-bridge/archive/master.tar.gz \
    | tar -xzC /var/www/html/ --strip-components=1


FROM php:7-apache

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && apt-get -qq update \
    && apt-get install -qq -y --no-install-recommends \
	zlib1g-dev \
	libmemcached-dev \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/* \
	&& pecl install memcached \
	&& docker-php-ext-enable memcached

COPY --chown=www-data --from=builder /var/www/html/ .
COPY --chown=www-data ./whitelist.txt .
