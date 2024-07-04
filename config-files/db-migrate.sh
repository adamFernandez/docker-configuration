#!/bin/bash

local_dir=$1
ext_db=$2

echo -e "\nMigrating local into $ext_db..."
ssh forge@206.189.117.88 "mysql --defaults-extra-file=./backups/$local_dir/.my.local.cnf $ext_db" < ./backups/local/$local_dir/latest/*.sql
if [ $? -eq 0 ]; then
    echo -e "\nDb $ext_db migration successful."
else
  echo -e "\nError: Db migration failed:"
  cat $error_file
  rm -f $error_file
  exit 1
fi
