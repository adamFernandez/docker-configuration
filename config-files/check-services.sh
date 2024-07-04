sed -i '' -e "s/API_TOKEN/CRAFT_AUTH_TOKEN/g" \
          -e "s/frontend/$1/g" docker-compose.dev.yml

sed -i '' -e "s/API_TOKEN/CRAFT_AUTH_TOKEN/g" \
          -e "s/frontend:/$1:/g" $1/.env