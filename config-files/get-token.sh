#!/bin/bash

. ./config-files/get/ports.sh 
. ./config-files/get/package_front.sh

TOKEN_VALUE=$(sed -n "s/INSERT INTO \`gqltokens\` VALUES (1,'Api','\([^']*\)'.*/\1/p" ./db-seed/*.sql)
# api_url="$([ $front_type = "astro" ] && echo "CRAFT_API_URL" || echo "GQL_HOST")"

if [ $1 ]; then
  sed -i '' -e 's/API_TOKEN:.*/API_TOKEN: '"$TOKEN_VALUE"'/' $front_type/.env
  sed -i '' -e 's/CRAFT_AUTH_TOKEN:.*/CRAFT_AUTH_TOKEN: '"$TOKEN_VALUE"'/' $front_type/.env
else
  sed -i '' -e 's/API_TOKEN:.*/API_TOKEN: '"$TOKEN_VALUE"'/' ./docker-compose.dev.yml
  sed -i '' -e 's/CRAFT_AUTH_TOKEN:.*/CRAFT_AUTH_TOKEN: '"$TOKEN_VALUE"'/' ./docker-compose.dev.yml
fi
echo "Current token in db: $(sh ./config-files/color-me.sh "$TOKEN_VALUE")"