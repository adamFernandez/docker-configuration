#!/bin/bash
. ./cms/.env

project_path=$1
user_name=$(sed "s/-/_/g" <<< "$project_path")
db_name=$2

. ./config-files/choose-project.sh

mkdir -p db-data/logs; 
curl -s GET -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/databases" > db-data/databases.json 
	
if  grep -q "$db_name" "./db-data/databases.json" ; then 
  echo -e "\nDatabase $db_name exists." 
  
  . ./config-files/db-migrate.sh "$project_path" "$db_name"
  # ssh forge@$server_ip "cd ${site_name}/cms && php craft clear-caches/data && php craft project-config/rebuild"
else 
  echo -e "\nNo $db_name db exists yet. Creating..."
  
  payload="{ \"name\": \"$db_name\" }"
  response=$(curl -s -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/databases" -d "$payload")
  echo "$response" > db-data/logs/db-$db_name-creation.log

  db_id=$(echo "$response" | grep -o "\"id\":[0-9]*" | awk -F"[,:]" '{print $2}')
  # echo "Database id is: $db_id"

  
  if [ $? -eq 0 ]; then
    echo -e "\nDatabase $db_name creation successful."

    . ./config-files/user-add-db.sh "$user_name" "$db_id"
    echo -e "\nDatabase $db_name added to user $user_name."

    sleep 1
    . ./config-files/db-migrate.sh "$project_path" "$db_name"

    # ssh forge@$server_ip "cd ${site_name}/cms && php craft clear-caches/data && php craft project-config/rebuild"

  else
    echo -e "\nError: Database creation failed."
    exit 1
  fi
fi;
