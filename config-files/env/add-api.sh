#!/bin/bash

. ./config-files/get/package_front.sh

sed -i '' -e "/^GQL_HOST=/s|=.*|=https:\/\/${1}\/api|" \
          -e "/^CRAFT_API_URL=/s|=.*|=https:\/\/${1}\/api|" "$front_type/.env"


            # -e "/^SITE_URL=/s|=.*|=https://${site_url}|" $front_type/.env
            
sed -i '' -e "/CRAFT_API_BASE_URL=/d" "$front_type/.env"