#!/bin/bash

docker-compose down $1; 
node_v=$(sh -c 'node -v'); 
echo -e "\nnode version is $node_v"; 
major_v=$(echo "$node_v" | cut -c2- | awk -F. '{print $1}')

if [ "$major_v" -lt 18 ]; then 
  echo "Switching to --lts..."
  . ~/.nvm/nvm.sh && nvm use --lts
fi

if ! command -v pnpm &> /dev/null; then
    echo -e "\npnpm is not installed on this machine."
    echo "Running from the $1 docker compose service..."
    # docker-compose exec $1 sh -c "pnpm install && pnpm run dev --host --port '$2'"
    docker-compose up "$1" -d
    sh -c "./config-files/wait-for-it.sh '$1' '$([ "$1" = "frontend" ] && echo "Nitro built" || echo "Local")'"
    echo -e "\n\tBackend URL: $(sh ./config-files/color-me.sh http://localhost:$3)"
    echo -e "\tFrontend URL: $(sh ./config-files/color-me.sh http://localhost:$2)"
else
  echo -e "\npnpm is installed."
  cd $1; 
  echo "Y" | pnpm install; 
  pnpm run dev --host --port $2; 
  cd ..; 
  echo -e "\nSwitching back to $node_v..."; 
    . ~/.nvm/nvm.sh && nvm use $node_v; 
fi
