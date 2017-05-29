FROM alpine:3.6

# Custom helper scripts to download PHP and manage PHP extensions
COPY bin /usr/local/bin/

ENV PHP_INI_DIR /usr/local/etc/php
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

# When using Composer, disable the warning about running commands as root/super user
ENV COMPOSER_ALLOW_SUPERUSER=1

# Persistent runtime dependencies
ENV DEPS \
        libedit \
        libxml2 \
        libbz2 \
        curl \
        libssl1.0 \
        ca-certificates

# PHP build dependencies which get removed
ENV BUILD_DEPS \
        autoconf \
        file \
        g++ \
        gcc \
        make \
        automake \
        libtool \
        bison \
        re2c \
        pkgconf \
        libc-dev \
        libedit-dev \
        curl-dev \
        bzip2-dev \
        krb5-dev \
        pcre-dev \
        zlib-dev \
        libxml2-dev \
        gnupg \
        openssl-dev

RUN set -x \
	  && addgroup -g 82 -S www-data \
	  && adduser -u 82 -D -S -G www-data www-data \
    && apk add --no-cache --virtual .build-deps $BUILD_DEPS \
    && apk add --no-cache $DEPS \
    # PHP
    && mkdir -p $PHP_INI_DIR/conf.d /usr/src \
    && cd /usr/src \
    && download-php \
    && cd php-* \
    && export CFLAGS="$PHP_CFLAGS" \
              CPPFLAGS="$PHP_CPPFLAGS" \
              LDFLAGS="$PHP_LDFLAGS" \
    && ./configure \
        # Core configure options
        --enable-phpdbg=no \
        --disable-rpath \
        # Bundled PHP extensions
        --enable-bcmath \
        --enable-calendar \
        --enable-mbstring \
        --enable-exif \
        --enable-ftp \
        --with-pcre-regex \
        --enable-mysqlnd \
        --with-openssl \
        --enable-zip \
        --enable-sysvsem \
        --enable-sysvshm \
        --enable-sysvmsg \
        --enable-shmop \
        --enable-sockets \
        --with-zlib \
        --with-zlib-dir \
        --with-bz2 \
        --with-curl \
        --with-mhash \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --disable-cgi \
        --with-libxml-dir=/usr \
        --with-libedit \
        --with-kerberos \
        --enable-opcache \
    && make -j "$(getconf _NPROCESSORS_ONLN)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
    # Remove dependencies
    && rm -rf /usr/src/* \
    && apk del .build-deps

COPY tags/latest /

CMD ["php", "-a"]
