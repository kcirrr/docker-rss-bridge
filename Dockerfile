FROM ubuntu:20.04 AS builder
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && c_rehash

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /var/www/html/ \
    && curl -SL https://github.com/RSS-Bridge/rss-bridge/archive/master.tar.gz \
    | tar -xzC /var/www/html/ --strip-components=1


FROM php:7-apache

ENV USER rssbridge
ENV UID 48373
ENV GID 48373

ENV APACHE_RUN_USER "${USER}"
ENV RUN_APACHE_GROUP "${USER}"

WORKDIR /var/www/html/

RUN groupadd -r "${USER}" --gid="${GID}" \
    && useradd --no-log-init -r -g "${GID}" --uid="${UID}" "${USER}" \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && apt-get update \
    && apt-get install --no-install-recommends --yes \
    zlib1g-dev \
    libmemcached-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pecl install memcached \
    && docker-php-ext-enable memcached \
    && sed -s -i -e "s/80/${PORT}/" /etc/apache2/ports.conf /etc/apache2/sites-available/*.conf

COPY --chown="${USER}" --from=builder /var/www/html/ .

USER "${UID}"

EXPOSE 8080
