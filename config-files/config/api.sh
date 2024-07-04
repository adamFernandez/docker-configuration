#!/bin/bash
. ./config-files/functions.sh
. ./config-files/get/ports.sh 
. ./config-files/get/package_front.sh

#### Grab current api url ####

# remote cms url variable name
api_url="$([ $front_type = "astro" ] && echo "CRAFT_API_URL" || echo "GQL_HOST")"

current_api=$(grep "$api_url=http[s]\?://" ./$front_type/.env | awk -F "//" '{print $2}')
full_url=$(grep "$api_url=" ./$front_type/.env | awk -F "=" '{print $2}')

# local cms url
local_url=$(grep "SITE_URL=" ./cms/.env | awk -F "=" '{print $2}')/api

# get selected api from config-frontend.sh
if [ -f "./config-files/env/logs/site_api.txt" ]; then
  site_api="$(<./config-files/env/logs/site_api.txt)"
# else
#   . ./config-files/env/config-frontend.sh
#   site_api="$(<./config-files/env/logs/site_api.txt)"
fi

#### Checking frontend connection to api from user ####

env=$( [[ $full_url = *"localhost"* ]] || [[ $full_url = "" ]] && echo "local" || echo "remote")

url=$( [ $env = "empty" ] || [ $env = "local" ] && echo $local_url || echo $full_url)
read -p $'\n'"Currently connected to $(sh ./config-files/color-me.sh $url ), happy? [y/n] " cmshappy


if [ $cmshappy == 'y' ]; then

  clear
  echo -e "\nConnection kept to $env $(sh ./config-files/color-me.sh $url )"

else   

  sh -c "./config-files/check-front-env.sh cms"
  current="$([ $env = "remote" ] && echo "Keep current ($full_url)")"
  options+=("$([ $env = 'local' ] && echo 'Keep l' || echo 'L')ocal ($local_url)" "Choose a different remote")
  [ -n "$current" ] && options+=("$current")
  echo ""
  read -r choice <<< $(create_free_list "${options[@]}")

  if [[ $choice = *"remote"* ]]; then

    echo "Choose new remote..."
    sh -c "./config-files/env/config-frontend.sh"
    full_url=$(grep "$api_url=" ./$front_type/.env | awk -F "=" '{print $2}')
    clear
    echo -e "\nFrontend will be connecting to $(sh ./config-files/color-me.sh $full_url )."

  fi

  if [[ $choice = *"current"* ]]; then
    
    sh -c "./config-files/env/add-api.sh $site_api"
    clear
    echo -e "\nCurrent remote $(sh ./config-files/color-me.sh https://$site_api/api ) kept."

  fi

  if [[ $choice = *"local"* ]]; then 

    clear
    echo -e "\nConnection to $(sh ./config-files/color-me.sh $local_url ) kept."
    sh -c "./config-files/check-front-env.sh cms"

  fi
fi
