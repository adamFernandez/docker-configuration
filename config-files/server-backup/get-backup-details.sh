#!/bin/bash

mkdir -p ./config-files/server-backup/logs

list="staging production"

for env in $list
do
  if [ ! -f "config-files/server-backup/logs/$env-api.txt" ]; then
    . ./config-files/server-backup/select-domain.sh "api" "Select $env api"
    echo -e "api=$site_api\nserver_ip=$server_ip" > ./config-files/server-backup/logs/$env-api.txt
  else
    output=$(grep "api=" ./config-files/server-backup/logs/$env-api.txt | awk -F "=" '{print $2}');
    echo -e "\nEnvironment $env has been set up already:";
    echo "- $(sh ./config-files/color-me.sh $output)";
  fi;
done