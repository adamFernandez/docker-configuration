#!/bin/bash

. ./config-files/get/ports.sh
. ./config-files/get/package_front.sh

api_var="$([ $front_type = "astro" ] && echo "CRAFT_AUTH_TOKEN" || echo "API_TOKEN")"
api_url="$([ $front_type = "astro" ] && echo "CRAFT_API_URL" || echo "GQL_HOST")"
token_value=$(sed -n "s/INSERT INTO \`gqltokens\` VALUES (1,'Api','\([^']*\)'.*/\1/p" ./db-seed/*.sql)

remove() {
  sed -i ''   -e "/$api_var=/d" \
              -e "/CRAFT_API_URL=/d" \
              -e "/CRAFT_API_BASE_URL=/d" \
              -e "/GQL_HOST=/d" \
              -e "/SITE_URL=/d" \
              -e "/NUXT_HMR_PORT=/d" \
              -e "/PORT=/d" "$front_type/.env" 
}

add() {
  cat <<EOF >> "$front_type/.env"
$api_var=$token_value
$api_url=http://localhost:$back_port/api
CRAFT_API_BASE_URL=http://localhost:$back_port
SITE_URL=http://localhost:$front_port
NUXT_HMR_PORT=$hmr_port
PORT=$front_port
EOF

sed -i '' -e "s/3[0-9]\{3\}/$front_port/g" \
          -e "s/8[0-9]\{3\}/$back_port/g" \
          -e "s/24[0-9]\{3\}/$hmr_port/g" "$front_type/.env"

}

if [ "$1" ]; then
  remove "$front_type"
  add "$front_type"
else 
  remove "$front_type"
fi