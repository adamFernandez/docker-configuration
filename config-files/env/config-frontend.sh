#!/bin/bash

. ./config-files/functions.sh
. ./cms/.env
. ./config-files/get/package_front.sh

mkdir -p ./config-files/env/logs

clear
echo -e "#### Frontend configuration ####\n"

check_source "servers"
echo -e "Servers:\n"
get_list "servers"
read -r server_id server_ip server_name  <<< $(create_select_list "$names" "servers")

echo "Server id: $server_id"

check_source "sites" "$server_id" "api"
echo -e "\nSites:\n"
get_list "sites" "$server_id" "" "api"
read -r site_id server_ip site_api <<< $(create_select_list "$names" "sites" "Select frontend api:")

# add selection value to file
echo "$site_api" > ./config-files/env/logs/site_api.txt

# add selection to frontend environment variables
sh -c "./config-files/env/add-api.sh $site_api"