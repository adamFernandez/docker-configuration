back_port=$(grep "SITE_URL=http://localhost:" ./cms/.env | awk -F ":" '{print $3}')
front_port=$(grep "PORT:" ./docker-compose.dev.yml | awk -F ":" '{print $4}')
hmr_port=$(grep "NUXT_HMR_PORT:" ./docker-compose.dev.yml | awk -F ":" '{print $2}' | tr -d " '")

mkdir -p ./config-files/get/logs

echo "$back_port" > ./config-files/get/logs/ports.txt
echo "$front_port" >> ./config-files/get/logs/ports.txt
echo "$hmr_port" >> ./config-files/get/logs/ports.txt

export back_port front_port hmr_port
