Last Call Media PHP Dockerfiles
===============================

PHP Dockerfiles is brought to you by your friends at [Last Call Media](https://www.lastcallmedia.com), these Docker files are for building various PHP related docker images for use with Drupal.

They all offer the following tools:

* PHP (with MySQL support, sqlite, GD, curl, mcrypt and an OpCode cache)
* Apache, configured to serve /var/www with an exposed port on 80
* Composer
* Drush Launcher

Environment Variables
---------------------
APACHE_DOCROOT (/var/www/html): The path to the docroot. To avoid configuration issues, keep your docroot below /var/www. If you change this, you will also want to change the working directory using the -w flag so when you use exec, you drop into the correct directory.
APACHE_RUN_USER (www-data): The user to run Apache as.
APACHE_RUN_GROUP (www-data): The group to run Apache as.
APACHE_REQUEST_WORKERS (150): The MaxRequestWorkers setting.
TZ (none): The Timezone to use for PHP.

Debugging
---------
The *-dev containers are intended for use in development environments only.  They include several extra tools that are not appropriate for production sites.

### Xdebug
To enable XDebug, set the `XDEBUG_ENABLE` environment variable. In most situations, this should be sufficient to allow remote debugging, but you may also find a need to change the `xdebug.remote_host` variable, which is set to `docker.host.internal` by default.

### Blackfire
The Blackfire PHP probe is installed on all of the -dev boxes.  It is configured to connect to a Blackfire `agent` container running alongside at blackfire:8707.  See the [Blackfire documentation](https://blackfire.io/docs/integrations/docker) for more information on setting this up.

Performance tuning
------------------
Check the memory usage of Apache:
```bash
ps -ylC apache2 | awk '{x += $8;y += 1} END {print "Apache Memory Usage (MB): "x/1024; print "Average Process Size (MB): "x/((y-1)*1024)}'
```

Available memory:
Calculate the amount of memory available INSIDE a docker container.
```bash
cat /sys/fs/cgroup/memory/memory.max_usage_in_bytes
```
