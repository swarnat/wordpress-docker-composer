FROM php:8.2-fpm-alpine3.16

ENV LIBRARY_PATH=/lib:/usr/lib
ENV BLACKFIRE_VERSION 1.86.6

RUN apk --no-cache add nginx supervisor curl git tzdata htop mysql-client \
  autoconf gcc libc-dev make  \
  zlib-dev \
  libcurl \
  libzip-dev curl-dev \
  libxml2-dev \
  libzip-dev \
  libzip \
  bzip2-dev \
  icu-dev \
  oniguruma-dev \
  postgresql-dev \
  libmemcached-dev \
  imap-dev \
  openssl-dev \
  libpng \
  libpng-dev \ 
  freetype-dev \
  libjpeg-turbo-dev && \
  ln -s /usr/bin/php8 /usr/bin/php && \
  rm /etc/nginx/http.d/* && \
  mkdir /etc/nginx/locations.d/ && \
  rm -rf /var/cache/apk/* && \
  mkdir /etc/nginx/nginxcacheGLOBAL && chown nobody.nobody /etc/nginx/nginxcacheGLOBAL


# Install PHP Extensions: GD, OPCache, SimpleXML, PDO, MBString, ZIP, MysqlI, CURL, SOAP, FileINfo, XML, INTL
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install opcache simplexml pdo mbstring zip pdo_mysql gd mysqli curl soap fileinfo xml intl && \
    docker-php-ext-enable opcache simplexml pdo mbstring zip pdo_mysql gd mysqli curl soap fileinfo xml intl && \
    pecl install redis-5.3.7 && \
    docker-php-ext-enable redis && \
    wget https://packages.blackfire.io/binaries/blackfire-php/$BLACKFIRE_VERSION/blackfire-php-alpine_amd64-php-82.so -O /usr/local/lib/php/extensions/no-debug-non-zts-20220829/blackfire.so

# Install WP-CLI and Composer
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Configure PHP-FPM
COPY config/fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY crons/ /var/www/crons/

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

COPY scripts/ /scripts
#COPY composer.json /var/www/composer.json

RUN mkdir /.composer/ && \
    chown nobody:nogroup /.composer/ -R && \
    chmod +x /scripts/startup.sh && \
    chown nobody:nogroup /var/www/ && \
    chown nobody:nogroup /var/www/crons -R && \
    chown nobody:nogroup /var/www/html/
    
# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/locations.d /etc/nginx/locations.d

# Configure PHP-FPM
COPY config/fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN mkdir /nginx && \
    chmod -R 777 /nginx
#  apk del gcc libc-dev make  musl-dev make autoconf oniguruma-dev libzip-dev curl-dev freetype-dev libpng-dev imap-dev
#  chown -R nobody.nobody /var/www/html && \
#  chown -R nobody.nobody /run && \
#  chown -R nobody.nobody /etc/nginx/locations.d/ && \
#  chown -R nobody.nobody /var/lib/nginx && \
#  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html

# Expose the port nginx is reachable on
EXPOSE 8080

#HEALTHCHECK --interval=5s --retries=4 CMD \
    #[[ "$(curl -o /dev/null -s -w "%{http_code}\n" http://localhost:8080/fpm-status)" == "200" ]]

RUN composer global config allow-plugins.isaac/composer-velocita true && \
    composer global require isaac/composer-velocita

ENTRYPOINT '/scripts/startup.sh'
