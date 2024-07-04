#!/bin/bash

# Run Queue shell script
#
# This shell script runs the Craft CMS queue via `php craft queue/listen`
# It waits until the database container responds, then runs any pending
# migrations / project config changes via the `craft-update` Composer script,
# then runs the queue listener that listens for and runs pending queue jobs
#
# @author    nystudio107
# @copyright Copyright (c) 2022 nystudio107
# @link      https://nystudio107.com/
# @license   MIT

if [[ "$IS_EXT" == true ]]; then
  echo "#### Switching to external database!!!"
  SERVER_DB=$EXT_DB_SERVER
  USER_DB=$EXT_DB_USER
  PASSWORD_DB=$EXT_DB_PASSWORD
  DATABASE_DB=$EXT_DB_DATABASE
  echo "Loading database: $DATABASE_DB"
else
  echo "#### Connecting to local database!!!"
  SERVER_DB=$DB_SERVER
  USER_DB=$DB_USER
  PASSWORD_DB=$DB_PASSWORD
  DATABASE_DB=$DB_DATABASE
  echo "Loading database: $DATABASE_DB"
fi

cd /var/www/project/cms

# Wait until the MySQL db container responds
echo "### Waiting for MySQL database"
until eval "mysql -h $SERVER_DB -u $USER_DB -p$PASSWORD_DB $DATABASE_DB -e 'select 1' > /dev/null 2>&1"
do
  sleep 1
done
# Wait until the `composer install` is done by looking for the `vendor/autoload.php` and `composer.lock` files
echo "### Waiting for vendor/autoload.php"
while [ ! -f "vendor/autoload.php" ] || [ ! -f "composer.lock" ]
do
  sleep 1
done
# Ensure permissions on directories Craft needs to write to
chown -R www-data:www-data /var/www/project/cms/storage
chown -R www-data:www-data /var/www/project/cms/web/cpresources
# Run any pending migrations/project config changes
su-exec www-data composer craft-update
# Run a queue listener
su-exec www-data php craft queue/listen 10
