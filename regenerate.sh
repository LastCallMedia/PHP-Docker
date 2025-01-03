#!/bin/bash

set -e

#####
#
# This shell script regenerates all images based on the "template."
#
# It also handles updating the docker-compose file.
#
# Usage:
# ./regenerate.sh
#
#####
php_versions=('7.0' '7.1' '7.2' '7.3' '7.4' '8.0' '8.1', '8.2', '8.3')
dc="version: '2'\nservices:\n"

version_at_least () {
  a_major=$(echo "$1" | awk -F'.' '{ print $1 }')
  a_minor=$(echo "$1" | awk -F'.' '{ print $2 }')
  b_major=$(echo "$2" | awk -F'.' '{ print $1 }')
  b_minor=$(echo "$2" | awk -F'.' '{ print $2 }')

  [[ "$a_major" -gt "$b_major" || ("$a_major" -eq "$b_major" && "$a_minor" -ge "$b_minor") ]]
}

for PHP_VERSION in "${php_versions[@]}"; do
  major=$(echo "$PHP_VERSION" | awk -F'.' '{ print $1 }')
  minor=$(echo "$PHP_VERSION" | awk -F'.' '{ print $2 }')

  # For php versions < 7.3, we need to specify xdebug version
  if version_at_least "$PHP_VERSION" "7.3"; then
    xdebug_3="1"
  else
    xdebug_3=""
  fi

  # Determine node version
  if version_at_least "$PHP_VERSION" "8.0"; then
    node_version=16
  elif version_at_least "$PHP_VERSION" "7.4"; then
    node_version=14
  else
    node_version=10
  fi

  # Determine compose version
  if version_at_least "$PHP_VERSION" "8.0"; then
    composer_version="2.3.10"
  elif version_at_least "$PHP_VERSION" "7.4"; then
    composer_version="2.0.11"
  else
    composer_version="1.10.20"
  fi

  # Determine terminus version
  if version_at_least "$PHP_VERSION" "8.0"; then
    terminus_version="3.0.7"
    terminus_sha="f8fd66afb825ba2314a3c1d9a0b0e7e3dedbe687668613bd511ff6b41c4c6516"
  else
    terminus_version="2.2.0"
    terminus_sha="73fcdf6ceee23731c20bff45f668bde09230af347670a92e5ca97c2c008ae6e0"
  fi

  # Configure options changed in 7.4
  # Negate the result, because bash returns `0` for true and `1` for false
  ! version_at_least "$PHP_VERSION" "7.4"
  php_at_least_7_4=$?

  dir="./$PHP_VERSION"
  rm -rf $dir
  mkdir -p $dir
  PHP_VERSION=$PHP_VERSION PHP_MAJOR_VERSION=$major PHP_MINOR_VERSION=$minor PHP_AT_LEAST_7_4=$php_at_least_7_4 COMPOSER_VERSION=$composer_version dockerize -template template/Dockerfile:$dir/Dockerfile
  PHP_VERSION=$PHP_VERSION PHP_MAJOR_VERSION=$major PHP_MINOR_VERSION=$minor PHP_AT_LEAST_7_4=$php_at_least_7_4 COMPOSER_VERSION=$composer_version dockerize -template template/test.yml:$dir/test.yml
  cp -r template/scripts "$dir/scripts"
  cp -r template/templates "$dir/templates"
  dc+="  \"$PHP_VERSION\":\n    image: lastcallmedia/php:$PHP_VERSION\n    build: $dir\n"

  devDir="${dir}-dev"
  rm -rf $devDir
  mkdir -p $devDir
  PHP_VERSION=$PHP_VERSION PHP_MAJOR_VERSION=$major PHP_MINOR_VERSION=$minor PHP_AT_LEAST_7_4=$php_at_least_7_4 COMPOSER_VERSION=$composer_version IS_DEV=true XDEBUG_3=$xdebug_3 NODE_MAJOR_VERSION=$node_version TERMINUS_VERSION=$terminus_version TERMINUS_SHA=$terminus_sha dockerize -template template/Dockerfile:$devDir/Dockerfile
  PHP_VERSION=$PHP_VERSION PHP_MAJOR_VERSION=$major PHP_MINOR_VERSION=$minor PHP_AT_LEAST_7_4=$php_at_least_7_4 COMPOSER_VERSION=$composer_version IS_DEV=true XDEBUG_3=$xdebug_3 NODE_MAJOR_VERSION=$node_version TERMINUS_VERSION=$terminus_version TERMINUS_SHA=$terminus_sha dockerize -template template/test.yml:$devDir/test.yml
  cp -r template/scripts "$devDir/scripts"
  cp -r template/templates "$devDir/templates"
  dc+="  \"$PHP_VERSION-dev\":\n    image: lastcallmedia/php:$PHP_VERSION-dev\n    build: $devDir\n"
done

printf "$dc" > docker-compose.yml
