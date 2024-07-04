#!/bin/bash

# Composer Install shell script
#
# This shell script runs `composer install` if either the `composer.lock` file or
# the `vendor/` directory is not present`
#
# @author    nystudio107
# @copyright Copyright (c) 2022 nystudio107
# @link      https://nystudio107.com/
# @license   MIT

# Check what db to load external or local
if [[ "$IS_EXT" == true ]]; then
  echo "#### Switching to external database!!!"
  SERVER_DB=$EXT_DB_SERVER
  USER_DB=$EXT_DB_USER
  PASSWORD_DB=$EXT_DB_PASSWORD
  DATABASE_DB=$EXT_DB_DATABASE
  echo "Loading databases: $DATABASE_DB"
else
  echo "#### Connecting to local database!!!"
  SERVER_DB=$DB_SERVER
  USER_DB=$DB_USER
  PASSWORD_DB=$DB_PASSWORD
  DATABASE_DB=$DB_DATABASE
  echo "Loading database: $DATABASE_DB"
fi


# Ensure permissions on directories Craft needs to write to
chown -R www-data:www-data /var/www/project/cms/storage
chown -R www-data:www-data /var/www/project/cms/web/cpresources
# Check for `composer.lock` & `vendor/autoload.php`
cd /var/www/project/cms

if [ ! -f "composer.lock" ] || [ ! -f "vendor/autoload.php" ]; then
    su-exec www-data composer install --verbose --no-progress --no-scripts --optimize-autoloader --no-interaction
    # Wait until the MySQL db container responds
    echo "### Waiting for MySQL database"
    until eval "mysql -h $SERVER_DB -u $USER_DB -p$PASSWORD_DB $DATABASE_DB -e 'select 1' > /dev/null 2>&1"
    do
      sleep 1
    done
    # Run any pending migrations/project config changes
    su-exec www-data composer craft-update
fi
