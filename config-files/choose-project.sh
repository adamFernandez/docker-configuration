. ./config-files/functions.sh

if [ ! -f data/domain/domain.log ]; then
  server_id=729408

  # check_source "servers"
  # get_list "servers"
  # read -r server_id server_ip server_name  <<< $(create_select_list "$names" "servers")

  check_source "sites" "$server_id"
  get_list "sites" "$server_id" "" "api"
  read -r site_id server_ip site_name <<< $(create_select_list "$api_list" "sites" "Select domain to clear db caches and rebuild from after migration:")

  # mkdir -p "./sites/${site_name}/db"
  # read -r u d p <<< $(db_details "$site_name" "$site_ip")

  # echo "Server ip: $server_ip"
  # echo "Server id: $server_id"
  clear
  mkdir -p ./data/domain/ && echo -e "\nSite chosen is: $site_name" > ./data/domain/domain.log
  # ssh forge@${server_ip} "cd ${site_name}/cms && php craft clear-caches/data && php craft project-config/rebuild"
else
  site_name=$(grep "Site chosen is:" ./data/domain/domain.log | awk -F ': ' '{print $2}')
  echo -e "\nProject cms domain is: $site_name."; 
fi

