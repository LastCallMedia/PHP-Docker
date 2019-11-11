#!/bin/bash

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
php_versions=('7.0' '7.1' '7.2' '7.3')
dc="version: '2'\nservices:\n"

for PHP_VERSION in "${php_versions[@]}"; do
  dir="./$PHP_VERSION"
  rm -rf $dir
  mkdir -p $dir
  PHP_VERSION=$PHP_VERSION dockerize -template template/Dockerfile:$dir/Dockerfile
  PHP_VERSION=$PHP_VERSION dockerize -template template/test.yml:$dir/test.yml
  cp -r template/scripts "$dir/scripts"
  cp -r template/templates "$dir/templates"
  dc+="  \"$PHP_VERSION\":\n    image: lastcallmedia/php:$PHP_VERSION\n    build: $dir\n"

  devDir="${dir}-dev"
  rm -rf $devDir
  mkdir -p $devDir
  PHP_VERSION=$PHP_VERSION IS_DEV=true dockerize -template template/Dockerfile:$devDir/Dockerfile
  PHP_VERSION=$PHP_VERSION IS_DEV=true dockerize -template template/test.yml:$devDir/test.yml
  cp -r template/scripts "$devDir/scripts"
  cp -r template/templates "$devDir/templates"
  dc+="  \"$PHP_VERSION-dev\":\n    image: lastcallmedia/php:$PHP_VERSION-dev\n    build: $devDir \n"
done

printf "$dc" > docker-compose.yml