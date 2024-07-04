#!/bin/bash

output=$(ssh forge@206.189.117.88 "sed -n -e 's/^user=//p' -e 's/^password=//p' ./backups/$1/.my.local.cnf")

 
db_user=$(echo "$output" | sed -n 1p)
db_pass=$(echo "$output" | sed -n 2p)

sed -i '' -e "/^user=/s|=.*|=$db_user|" \
           -e "/^password=/s|=.*|=$db_pass|" ./.my.ext.cnf

sed -i '' -e "/^EXT_DB_USER=/s|=.*|=$db_user|" \
           -e "/^EXT_DB_PASSWORD=/s|=.*|=$db_pass|" \
           -e "/^EXT_DB_DATABASE=/s|=.*|=${db_user}_local|" ./cms/.env


# echo "User is: $db_user"
# echo "Pass is: $db_pass"