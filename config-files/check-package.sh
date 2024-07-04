#!/bin/bash
. ./config-files/functions.sh
. ./config-files/get/ports.sh 
. ./config-files/get/package_front.sh

###### Connect to frontend docker service
connect_to_docker_front() {
  echo "Running from the $front_type docker compose service..."
  docker-compose up "$front_type" -d
  sh -c "./config-files/wait-for-it.sh '$front_type' '$([ "$front_type" = "frontend" ] && echo "Nitro" || echo "Local")'"
  echo -e "\nAnd once more here they are: "
  echo -e "\n\tBackend URL: $(sh ./config-files/color-me.sh http://localhost:$back_port)"
  echo -e "\tFrontend URL: $(sh ./config-files/color-me.sh http://localhost:$front_port)"
}

. ./config-files/config/api.sh


# #### Checking package manager with environment and user ####

list="pnpm yarn"

if [ "$package" != "pnpm" ] && [ "$package" != "yarn" ]; then 
  # create_list "$list" "Choose package manager:"
  echo -e "\nNo lock find has been found.\n"
  read -r choice <<< $(create_list "$list" "Choose package manager: " )
  package="$choice"
  read -p $'\n'"This will run the frontend with $package, ok? [y/n] " pmhappy
else
  read -p $'\n'"Running frontend currently with $package, happy? [y/n] " pmhappy

fi

current_package=$package;

if [ $pmhappy == 'y' ]; then
  package=$current_package;
  echo "Running frontend with $package";
else 
  rm -rf $front_type/node_modules $front_type/.pnpm-store $front_type/pnpm-lock.yaml $front_type/yarn.lock
  package=$( [ $current_package = "yarn" ] && echo "pnpm" || echo "yarn" )
  echo -e "\nSwitching package manager from $current_package to $package..."
fi



# #### Installing frontend based on above selection ####

docker-compose down $front_type; 
node_v=$(sh -c 'node -v'); 
echo -e "\nnode version is $node_v"; 
major_v=$(echo "$node_v" | cut -c2- | awk -F. '{print $1}')

if [ "$major_v" -lt 18 ]; then 
  echo "Switching to --lts..."
  . ~/.nvm/nvm.sh && nvm use --lts
fi

if ! command -v $package &> /dev/null; then
    echo -e "\n$package is not installed on this machine."
    connect_to_docker_front
else
  echo -e "\n$package is installed."
  echo "Running $front_type locally..."
  cd $front_type; 
  
  # command=$( [ $package = "pnpm" ] && echo "pnpm run dev" || ( [ $package = "yarn" ] && echo "yarn dev" || echo "No package lock file found" ) )
  if [ $package = "pnpm" ]; then
    echo "Y" | $package install; 
    pnpm run dev --port $front_port;
  else 
    yarn install;
    yarn dev --port $front_port;
  fi;

  cd ..; 
  echo -e "\nSwitching back to $node_v..."; 
    . ~/.nvm/nvm.sh && nvm use $node_v; 
fi
