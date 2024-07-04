#!/bin/bash
. ./config-files/functions.sh
. ./config-files/get/ports.sh 
. ./config-files/get/package_front.sh

# #### Running a frontend build ####

docker-compose down $front_type; 
node_v=$(sh -c 'node -v'); 
echo -e "\nnode version is $node_v"; 
major_v=$(echo "$node_v" | cut -c2- | awk -F. '{print $1}')

if [ "$major_v" -lt 18 ]; then 
  echo "Switching to --lts..."
  . ~/.nvm/nvm.sh && nvm use --lts
fi


cd $front_type; 

# command=$( [ $package = "pnpm" ] && echo "pnpm run dev" || ( [ $package = "yarn" ] && echo "yarn dev" || echo "No package lock file found" ) )
if [ $package = "pnpm" ]; then
  echo "Y" | $package install; 
  pnpm build;
  pnpm run dev --host --port $front_port;
else 
  yarn install;
  yarn build;
  yarn dev --host --port $front_port;
fi;

cd ..; 
echo -e "\nSwitching back to $node_v..."; 
  . ~/.nvm/nvm.sh && nvm use $node_v; 
