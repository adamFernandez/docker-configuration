#!/bin/bash

# set -x

. ./config-files/functions.sh

. ./config-files/server-backup/get-backup-details.sh

list="staging production"

for env in $list
do
  api=$(grep "api=" ./config-files/server-backup/logs/$env-api.txt | awk -F "=" '{print $2}')
  ip=$(grep "server_ip=" ./config-files/server-backup/logs/$env-api.txt | awk -F "=" '{print $2}')
  # echo "\nSite api: $api"
  # echo "Server ip: $ip"
  read -r u d p i <<< $(db_details "$api" "$ip")

  # echo "\n$env $api $ip $u $d $p $i"

  # Update mysql credentials on local cnf and .env files
  sed -i '' -e "/^user=/s|=.*|=$u|" \
             -e "/^password=/s|=.*|=$p|" ./.my.ext.cnf

  sed -i '' -e "/^EXT_DB_USER=/s|=.*|=$u|" \
             -e "/^EXT_DB_PASSWORD=/s|=.*|=$p|" \
             -e "/^EXT_DB_DATABASE=/s|=.*|=${u}_local|" ./cms/.env

  backup_path="backups/$u"
  mkdir -p $backup_path/testing/$env/latest

  read -r ip <<< $(sort_server "$i")
  # echo "\nProcessed ip: $ip\n\n"
  
  ssh forge@$ip "mkdir -p '${backup_path}/testing/$env/latest'"
  rsync -a ./.my.ext.cnf forge@$ip:backups/$u/testing/$env/.my.ext.cnf

  dump_database "${backup_path}/testing/$env" "$ip" "$d"

done









