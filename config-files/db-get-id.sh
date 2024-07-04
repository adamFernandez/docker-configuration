#!/bin/bash
. ./cms/.env

name=$1
payload=$2

response=$(curl -s -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/databases" -d "$payload")
echo "$response" > db-data/logs/db-$name-creation.log

db_id=$(echo "$response" | grep -o "\"id\":[0-9]*" | awk -F"[,:]" '{print $2}')
echo "Database id is: $db_id"