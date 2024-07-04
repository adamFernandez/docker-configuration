#!/bin/bash
. ./cms/.env

name=wl_t2

# curl -s GET -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/database-users"  > db-data/users.json 

u_id=$(curl -s -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/database-users" | grep -o "\"id\":[0-9]*,\"name\":\"$name\"" | awk -F"[,:]" '{print $2}')

# # Extract user information using grep from a json file (json formatted)
# u_id=$(grep -B1 "\"name\": \"$name\"" "./db-data/users.json" | grep "\"id\":" | awk -F: '{gsub(/[," ]/, ""); print $2}')

echo "User id is: $u_id"

# Add database to user:

payload="{ \"databases\": [ 12345 ] }"

# curl POST -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" "https://forge.laravel.com/api/v1/servers/731686/database-users/$u_id" 

curl -X PUT -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" "https://forge.laravel.com/api/v1/servers/731686/database-users/$u_id"
