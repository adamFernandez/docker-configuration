#!/bin/bash

api=$1
message=$2

. ./config-files/functions.sh
. ./cms/.env
. ./config-files/get/package_front.sh

echo -e "#### $message ####\n"

check_source "servers"
echo -e "Servers:\n"
get_list "servers"
read -r server_id server_ip server_name  <<< $(create_select_list "$names" "servers")

check_source "sites" "$server_id" "$1"
echo -e "\nSites:\n"
get_list "sites" "$server_id" "" "$1"
read -r site_id server_ip site_api <<< $(create_select_list "$names" "sites" "Select api:")

export server_id server_ip server_name site_id site_api