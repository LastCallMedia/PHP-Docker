FROM php:7.3-apache

# common-php70
ENV DEBIAN_FRONTEND noninteractive
ENV APACHE_DOCROOT /var/www/html
ENV PATH=/var/www/vendor/bin:$PATH
ENV COMPOSER_MEMORY_LIMIT "-1"

RUN apt-get update && apt-get install -y --no-install-recommends \
      # for bz2
      bzip2 libbz2-dev \
      # for ftp
      libssl-dev \
      # for gd
      libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
      # for intl
      libicu-dev \
      # for dom
      libxml2-dev \
      # for ldap
      libldap2-dev \
      # for mysql
      mariadb-client \
      # for ssh client only
      openssh-client \
      # For image optimization
      jpegoptim \
      optipng \
      pngquant \
      # php7.3 needs zlib1g-dev and libzip-dev for the zip extension
      # https://github.com/docker-library/php/issues/61#issuecomment-468874705
      zlib1g-dev \
      libzip-dev \
      # for git
      git \
      # for composer
      unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install -j$(nproc) \
      bcmath \
      bz2 \
      calendar \
      exif \
      ftp \
      gd \
      gettext \
      intl \
      ldap \
      mysqli \
      opcache \
      pcntl \
      pdo_mysql \
      shmop \
      soap \
      sockets \
      sysvmsg \
      sysvsem \
      sysvshm \
      zip \
    && pecl install redis apcu \
    && docker-php-ext-enable redis apcu

# Configure Apache:
RUN a2enmod rewrite headers expires \
  && sed -i "/DocumentRoot \/var\/www\/html/c\\\tDocumentRoot \$\{APACHE_DOCROOT\}" /etc/apache2/sites-enabled/000-default.conf \
  # Preemptively add a user 1000, for use with $APACHE_RUN_USER on osx
  && adduser --uid 1000 --gecos 'My OSX User' --disabled-password osxuser

# Install Composer.
ARG COMPOSER_VERSION=1.9.1
RUN COMPOSER_SHA384=$(curl https://composer.github.io/installer.sig) \
  && curl -fsSL -o composer-setup.php https://getcomposer.org/installer \
  && echo "$COMPOSER_SHA384 composer-setup.php" | sha384sum -c - \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Install Dockerize.
ARG DOCKERIZE_VERSION=v0.6.1
ARG DOCKERIZE_SHA256=1fa29cd41a5854fd5423e242f3ea9737a50a8c3bcf852c9e62b9eb02c6ccd370
RUN curl -fsSOL https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && echo "$DOCKERIZE_SHA256 dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz" | sha256sum -c - \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Install Drush Launcher. Whereas previously we installed Drush globally, we no longer do,
# since it's expected that D8 sites will include their own copy of Drush, and Drush 9+ is
# incompatible with Drupal < 8.
# @todo: Is the launcher even needed? We add /var/www/vendor/bin on the global path.
ARG DRUSH_LAUNCHER_VERSION=0.6.0
ARG DRUSH_LAUNCHER_SHA256=c3f32a800a2f18470b0010cd71c49e49ef5c087f8131eecfe9b686dc1f3f3d4e
RUN curl -fsSOL https://github.com/drush-ops/drush-launcher/releases/download/$DRUSH_LAUNCHER_VERSION/drush.phar \
  && echo "$DRUSH_LAUNCHER_SHA256 drush.phar" | sha256sum -c - \
  && mv drush.phar /usr/bin/drush && chmod +x /usr/bin/drush

# Pre-trust Github host certificates.
RUN ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

ADD templates /templates
ADD scripts/* /usr/local/bin/
ENTRYPOINT ["lcm-php-entrypoint"]
# /common-php70

# NodeJS + Yarn
ARG NODE_MAJOR_VERSION=10
RUN apt-get update \
  && apt-get install -y apt-transport-https lsb-release gnupg > /dev/null 2>&1 \
  && curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://deb.nodesource.com/node_$NODE_MAJOR_VERSION.x $(lsb_release --codename | cut -f2) main" > /etc/apt/sources.list.d/nodesource.list \
  && echo "deb-src https://deb.nodesource.com/node_$NODE_MAJOR_VERSION.x $(lsb_release --codename | cut -f2) main" >> /etc/apt/sources.list.d/nodesource.list \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get install -y nodejs \
  && apt-get install -y --no-install-recommends yarn \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# XDebug
RUN pecl install xdebug \
  && docker-php-ext-enable xdebug \
  && echo "xdebug.default_enable=0\nxdebug.coverage_enable=0" > $PHP_INI_DIR/conf.d/xdebug.ini

# Blackfire Probe. Note: We do not install Blackfire CLI. You will
# need that in order to trigger Blackfire tests. The probe just instruments
# things on the server side.
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Terminus.
ARG TERMINUS_VERSION=2.2.0
ARG TERMINUS_SHA256="73fcdf6ceee23731c20bff45f668bde09230af347670a92e5ca97c2c008ae6e0"
RUN curl -fsSOL https://github.com/pantheon-systems/terminus/releases/download/$TERMINUS_VERSION/terminus.phar \
  && echo "$TERMINUS_SHA256 terminus.phar" | sha256sum -c - \
  && mv terminus.phar /usr/local/bin/terminus \
  && chmod +x /usr/local/bin/terminus

# Gulp-cli.
RUN npm i --no-cache -g gulp-cli
ADD Dockerfile /tmp

