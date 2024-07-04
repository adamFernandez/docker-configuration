include $(PWD)/cms/.env
CURRENT?=$(shell basename $(CURDIR))
CONTAINER?=$(shell basename $(CURDIR))-php-1

front_type:=$(if $(wildcard ./astro),astro,frontend)
project_name:=$(shell bash -c 'sed "s/-/_/g" <<< "$(CURRENT)"');

back_port ?= $(shell grep "SITE_URL=http://localhost:" ./cms/.env | awk -F ":" '{print $$3}')
front_port ?= $(shell grep "PORT:" ./docker-compose.dev.yml | awk -F ":" '{print $$4}')
hmr_port ?= $(shell grep "NUXT_HMR_PORT:" ./docker-compose.dev.yml | awk -F ":" '{print $$2}')

MYSQL_CONTAINER?=$(shell basename $(CURDIR))-mysql-1
FILE_PATH?=$(shell bash -c 'read -p "Path to db: " dbpath; echo $$dbpath' )
TABLE?=$(shell bash -c 'read -p "Table Name: " dbtable; echo $$dbtable' )
DB_NAME?=$(shell bash -c 'read -p "DB Name: " dbname; echo $$dbname' )
MYSQL_PASSWORD?=$(shell bash -c 'read -s -p "Db pass: " dbpass; echo $$dbpass' )
DUMP_NAME?=$(shell bash -c 'read -p "Filename: " dbname; echo $$dbname')
DEPENDENCIES?=$(shell bash -c 'read -p "Dependencies: " dependd; echo $$dependd')
TIMESTAMP?=$(shell date +"%Y-%m-%d--%H%M%S")
VERSION?=$(shell docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" project -N -B -e "SELECT version FROM info WHERE id=1")
craft_token?=$(shell docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" project -N -B -e "SELECT accessToken FROM gqltokens WHERE id=1")
EXT_VERSION?=$(shell ssh forge@206.189.117.88 "mysql --defaults-extra-file=backups/$(CURRENT)/.my.local.cnf ${EXT_DB_DATABASE} -N -B -e 'SELECT version FROM info WHERE id=1'")
DB_DUMP=${EXT_DB_DATABASE}-$(TIMESTAMP)_$(VERSION).sql
EXT_DB_DUMP=${EXT_DB_DATABASE}-$(TIMESTAMP)_$(EXT_VERSION).sql

local=backups/local/$(CURRENT)
server=backups/server/$(CURRENT)

.PHONY: push-staging dev remove dump check_dir import add-dev add-save front clean composer craft nuke ssh up schema

craft_version:
# @VERSION=$$(docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" project -N -B -e "SELECT version FROM info WHERE id=1"); 
	@echo "Craft Version: $(VERSION)"; 
push-staging:
	@./config-files/db-create.sh $(CURRENT) $(EXT_DB_USER)_staging

### LOCAL ENVIRONMENT COMMANDS ###
dump: check_dir
	@docker exec $(MYSQL_CONTAINER) sh -c 'exec mysqldump --no-create-db -hlocalhost -uroot -p"$$MYSQL_ROOT_PASSWORD" project' > "./backups/$(DUMP_NAME)--$(TIMESTAMP)_$(VERSION).sql"
check_dir:  
	@mkdir -p ./backups
import: 
	@docker cp ./$(FILE_PATH) $(MYSQL_CONTAINER):/tmp/import.sql
	@docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" -e "DROP DATABASE IF EXISTS project; CREATE DATABASE project; USE project; source /tmp/import.sql;"
	@docker exec -i $(MYSQL_CONTAINER) sh -c 'rm /tmp/import.sql'
# Original import command
# @docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" project < $(FILE_PATH)
	@docker exec -i $(CONTAINER) ./craft clear-caches/data
	@docker exec -i $(CONTAINER) ./craft project-config/rebuild
# ${EXT_FORGE_PASSWORD}
backup-all:
	@mkdir -p ${local}/latest
	@mkdir -p ${server}/latest

	@if [ -n "$$(ls -A ${local}/latest)" ]; then \
		echo "The 'latest' directory is not empty"; \
		mv ./${local}/latest/*.sql ./${local}/; \
		docker exec $(MYSQL_CONTAINER) sh -c 'exec mysqldump -hlocalhost --no-create-db -u root -psecret project' > "${local}/latest/${DB_DUMP}"; \
	else \
		echo "The 'latest' directory is empty"; \
		docker exec $(MYSQL_CONTAINER) sh -c 'exec mysqldump -hlocalhost --no-create-db -u root -psecret project' > "${local}/latest/${DB_DUMP}"; \
	fi

	@scp ./${local}/latest/*.sql forge@206.189.117.88:tmp/local.sql; 
	@echo "Done backing up ${DB_DUMP} from local db"
	
	@if [ -n "$$(ls -A ${server}/latest)" ]; then \
		echo "The 'latest' directory is not empty"; \
		mv ./${server}/latest/*.sql ./${server}/; \
		ssh forge@206.189.117.88 "mkdir -p tmp && mysqldump -u ${EXT_FORGE_USER} -p${EXT_FORGE_PASSWORD} ${EXT_DB_DATABASE} > tmp/dump.sql"; \
		scp forge@206.189.117.88:tmp/dump.sql  ${server}/latest/${DB_DUMP}; \
	else \
		echo "The 'latest' directory is empty"; \
		ssh forge@206.189.117.88 "mkdir -p tmp && mysqldump -u ${EXT_FORGE_USER} -p${EXT_FORGE_PASSWORD} ${EXT_DB_DATABASE} > tmp/dump.sql"; \
		scp forge@206.189.117.88:tmp/dump.sql ${server}/latest/${DB_DUMP}; \
	fi

	@echo "Done backing up ${DB_DUMP} from server db"

	@echo "Migrating database into ${EXT_DB_DATABASE}"
	@ssh forge@206.189.117.88 "mkdir -p tmp && mysql --defaults-extra-file=backups/${CURRENT}/.my.local.cnf ${EXT_DB_DATABASE} < tmp/local.sql"

backup-server: 
	@mkdir -p ${local}/latest ${server}/latest

	@if [ -n "$$(ls -A ${server}/latest)" ]; then \
		echo "The 'latest' directory is not empty"; \
		mv ./${server}/latest/*.sql ./${server}/; \
		ssh forge@206.189.117.88 "mkdir -p tmp && mysqldump -u ${EXT_FORGE_USER} -p${EXT_FORGE_PASSWORD} ${EXT_DB_DATABASE} > tmp/dump.sql"; \
		scp forge@206.189.117.88:tmp/dump.sql  ${server}/latest/${EXT_DB_DUMP}; \
	else \
		echo "The 'latest' directory is empty"; \
		ssh forge@206.189.117.88 "mkdir -p tmp && mysqldump -u ${EXT_FORGE_USER} -p${EXT_FORGE_PASSWORD} ${EXT_DB_DATABASE} > tmp/dump.sql"; \
		scp forge@206.189.117.88:tmp/dump.sql ${server}/latest/${EXT_DB_DUMP}; \
	fi

	@echo "Done backing up ${DB_DUMP} from server db"

### DATABASE COMMANDS ####
db_external:
	@sed -i '' -e '/^IS_EXT=/s/=.*/='"true"'/' cms/.env; \
	make up;

db_local: 
	@sed -i '' -e '/^IS_EXT=/s/=.*/='"false"'/' cms/.env; \
	make up;

list-databases:
	@echo "Listing databases on external server..."
	@databases=$$(ssh forge@206.189.117.88 "mysql -u ${EXT_FORGE_USER} -p -e 'SHOW DATABASES;' | tail -n +2"); \
	PS3='Choose a database: '; \
	select db_name in $$databases; do \
		if [ "$$db_name" ]; then \
			echo "You selected: $$db_name"; \
			SELECTED_DB=$$db_name; \
			echo "Selected database: $$SELECTED_DB"; \
			break; \
		else \
			echo "Invalid option. Please try again."; \
		fi; \
	done
show-db: list-databases
	@echo "database $$SELECTED_DB"
drop-db:
	@docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" -e "DROP DATABASE ${DB_NAME};"
view_table_content:
	@docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" project -e "SELECT username, password FROM ${TABLE};"
drop-table:
	@docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" project -e "DROP TABLE ${TABLE};"
create-db:
	@docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
schema: 
	@docker exec -i $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" -e "SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = 'project';"
	@docker exec -it $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" -e "SELECT default_collation_name FROM information_schema.SCHEMATA WHERE schema_name = 'project';"
tables:
	@docker exec -it $(MYSQL_CONTAINER) mysql --defaults-extra-file="/var/lib/.my.local.cnf" project -e "SHOW TABLES;"

#### CRAFT INFO COMMANDS #####
ext-version: 
# echo $(EXT_VERSION)
	@ssh forge@206.189.117.88 "mysql --defaults-extra-file=backups/${EXT_DB_USER}/.my.local.cnf ${EXT_DB_DATABASE} -N -B -e 'SELECT version FROM info WHERE id=1'"
craft-token:
	@echo $(craft_token)
craft-info: 
	@docker exec -i $(CONTAINER) ./craft update/info
cache: 
	@docker exec -i $(CONTAINER) ./craft clear-caches/data
	@docker exec -i $(CONTAINER) ./craft project-config/rebuild
restore:
	@docker cp $(FILE_PATH) $(CONTAINER):/tmp/restore.sql
	@docker exec -i $(CONTAINER) sh -c './craft db/restore /tmp/restore.sql'
	@docker exec -i $(CONTAINER) sh -c 'rm /tmp/backup.sql'
migrate-down:
	@docker exec -it $(CONTAINER) sh -c './craft migrate/history'
# @docker exec -it $(CONTAINER) sh -c './craft migrate/down '
project-config-apply:
	@docker exec -it $(CONTAINER) sh -c './craft project-config/apply'

create-user:
	@docker-compose exec -u root php sh -c 'adduser --disabled-password --gecos "" alesito && chown -R alesito:alesito /var/www/project/cms'

delete-user:
	@docker compose exec -it php sh -c 'sed -i "/^alesito:/d" /etc/passwd && sed -i "/^alesito:/d" /etc/group'

#craft:
#	@docker compose exec -u alesito php sh -c './craft $(filter-out $@,$(MAKECMDGOALS))'

#composer:
#	@docker compose exec -u alesito php sh -c 'composer $(filter-out $@,$(MAKECMDGOALS))'

### FRONTEND COMMANDS ###
yarn-remove:
	@docker-compose exec -i $(front_type) yarn remove $(DEPENDENCIES)
	@docker-compose restart $(front_type)
add-dev:
	@docker-compose exec -i $(front_type) yarn add $(DEPENDENCIES) --dev
	@docker-compose restart $(front_type)
add:
	@docker-compose exec -i $(front_type) yarn add $(DEPENDENCIES)  
	@docker-compose restart $(front_type)
outdated:
	@docker-compose exec -i $(front_type) yarn outdated
upgrade:
	@docker-compose exec -it $(front_type) yarn upgrade --latest
	@docker-compose restart $(front_type)
yarn:
	@docker-compose exec -it $(front_type) yarn install
	@docker-compose restart $(front_type)
frontend-upgrade:
# @docker-compose exec -i frontend npx nuxi upgrade
	@docker-compose restart $(front_type)
front-restart: 
	@docker-compose restart $(front_type)
front-recreate: 
	@docker-compose up --build --force-recreate -V $(front_type)

### ORIGINAL DOCKER COMMANDS ###
clean:
	@rm -f cms/composer.lock
	@rm -rf cms/vendor/

composer: up
	@docker exec -it ${CONTAINER} su-exec www-data composer \
		$(filter-out $@,$(MAKECMDGOALS))
craft: up
	@docker exec -it ${CONTAINER} su-exec www-data php craft \
 		$(filter-out $@,$(MAKECMDGOALS))
nuke:
	@docker-compose down -v
	@rm -f cms/composer.lock
	@rm -rf cms/vendor/
	@docker-compose up --build --force-recreate -V
ssh:
	@docker exec -it ${CONTAINER} su-exec www-data /bin/sh

check-token:
	echo "Token is: $(craft_token)"

### INITIAL CHECKS ###

# Files for check config
check_dirs := docker-config config-files
check_files := docker-compose.dev.yml .my.local.cnf .my.ext.cnf .gitignore $(front_type)/.gitignore cms/.env $(front_type)/.env $(front_type)/Dockerfile $(check_dirs)

check-config: 
	@ssh -q -o BatchMode=yes -o ConnectTimeout=5 "forge@206.189.117.88" "echo 2>&1" && echo "SSH key already exists." || echo "SSH key not added to the server. Please add the SSH key and try again." 

	@if $(foreach file,$(check_files), [ -e "$(file)" ] &&) true; then \
		echo "Config files already exist."; \
	else \
		echo "Copying config files and folders..."; \
		if [ "$(front_type)" == "astro" ]; then \
			rsync -avz --exclude 'frontend/' forge@206.189.117.88:config/ ./; \
			rsync -avz --no-relative --exclude='frontend/' forge@206.189.117.88:config/frontend/ ./astro/; \
			scp forge@206.189.117.88:config/astro/astro.config.local.mjs ./astro; \
		else \
			rsync -avz --exclude 'astro/' forge@206.189.117.88:config/ ./; \
		fi; \
		echo "Files copied successfully."; \
	fi;

	@if [ "$(front_type)" = "astro" ]; then \
		./config-files/check-services.sh $(front_type); \
	fi; \
	rm -rf cms/config/project; \
	make check_db

### LARAVEL FORGE COMMANDS ###

check_db:	
# databases=$(shell bash -c 'curl GET -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/databases"'); 
# echo $$databases; 
	@mkdir -p db-data/logs; \
	curl -s GET -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/databases" > db-data/databases.json ; \
	name=$(shell bash -c 'sed "s/-/_/g" <<< "$(CURRENT)"'); \
	if  grep -q "$${name}_local" "./db-data/databases.json" ; then \
		echo "Database $${name}_local exists." ; \
		./config-files/get-ext-cnf.sh $(CURRENT); \
	else \
		echo "\nNo $(CURRENT) db exists yet. Creating..."; \
		make new_db; \
		echo "Database $${name}_local created" ; \
	fi;
# make import_base_db; 
rename_ext:
	@sed -i '' -e '/^EXT_DB_DATABASE=/s/=.*/="$(project_name)_local"/' -e '/^EXT_DB_PASSWORD=/s/=.*/='"$${pass}"'/' -e '/^EXT_DB_USER=/s/=.*/='"$(project_name)"'/' cms/.env; \
	sed -i '' -e '/^user=/s/=.*/="$(project_name)"/' -e '/^password=/s/=.*/='"$${pass}"'/' .my.ext.cnf; 

new_db:
	@name=$(shell bash -c 'sed "s/-/_/g" <<< "$(CURRENT)"'); \
	pass=$(shell bash -c 'openssl rand -base64 15 | tr -d "+/=" | cut -c1-20'); \
	payload="{ \"name\": \"$${name}_local\", \"user\": \"$${name}\", \"password\": \"$${pass}\" }"; \
	curl -s -k -X POST -H "Authorization: Bearer ${AUTH}" -H "Accept: application/json" -H "Content-Type: application/json" "https://forge.laravel.com/api/v1/servers/731686/databases" -d "$$payload" > db-data/logs/database-creation.log; \
	sed -i '' -e '/^EXT_DB_DATABASE=/s/=.*/='"$${name}_local"'/' -e '/^EXT_DB_PASSWORD=/s/=.*/='"$${pass}"'/' -e '/^EXT_DB_USER=/s/=.*/='"$${name}"'/' cms/.env; \
	sed -i '' -e '/^user=/s/=.*/='"$${name}"'/' -e '/^password=/s/=.*/='"$${pass}"'/' .my.ext.cnf; 

	@ssh forge@206.189.117.88 "mkdir -p backups/$(CURRENT)"; \
	scp .my.ext.cnf forge@206.189.117.88:backups/$(CURRENT)/.my.local.cnf;

# sed -i '' -e '/^# DB_DATABASE=/s/=.*/='"$${name}_local"'/'  cms/.env;

import_base_db:
	scp db-seed/*.sql forge@206.189.117.88:backups/craft4/; \
	ssh forge@206.189.117.88 "mysql -u${EXT_DB_USER} -p${EXT_DB_PASSWORD} ${EXT_DB_DATABASE} < backups/craft4/*.sql"

set-permissions:
	@if $(foreach file,$(wildcard ./config-files/**/*.sh), [ -x "$(file)" ] &&) true; then \
		 echo "All files have execute permission."; \
	else \
		echo "Checking permissions for shell scripts in config-files directory..."; \
		for file in $$(find ./config-files -name "*.sh"); do \
			if [ -x "$$file" ]; then \
				echo "$$file has execute permission."; \
			else \
				echo "$$file does not have execute permission. Adding it..."; \
				chmod +x "$$file"; \
			fi; \
		done; \
		echo "Permissions checked and set for shell scripts in config-files directory."; \
	fi;
unset-permissions:
	@find ./config-files -name "*.sh" -exec chmod -x {} +
	@echo "Permissions unset for all shell scripts in config-files directory."

check-env:
	@./config-files/check-env.sh

get-token: 
	@./config-files/get-token.sh

get-token-cms:
	@./config-files/get-token.sh cms

find-port:
	@if grep -q "8888" "./cms/.env" ; then \
		$(eval NGINX_PORT := $(shell ./config-files/check-port.sh NGINX 8881 8900)) \
		$(eval FRONTEND_PORT := $(shell ./config-files/check-port.sh FRONTEND 3001 3201)) \
		$(eval HMR_PORT := $(shell ./config-files/check-port.sh HMR 24671 24681)) \
		$(eval NEW_SITE_NAME := $(CURRENT)) \
		echo "\nNGINX using port $(NGINX_PORT)"; \
		echo "FRONTEND using port $(FRONTEND_PORT)"; \
		echo "HMR using port $(HMR_PORT)"; \
		echo "\nChanging SITE_NAME to $(NEW_SITE_NAME)"; \
		sed -i '' -e 's/8888/$(NGINX_PORT)/g' -e 's/3000/$(FRONTEND_PORT)/g' -e 's/24670/$(HMR_PORT)/g' docker-compose.dev.yml; \
		sed -i '' -e "s/8888/${NGINX_PORT}/g" -e "/^SITE_NAME=/s/=.*/=\"${NEW_SITE_NAME}\"/" -e "s/3000/${FRONTEND_PORT}/g" -e "/^LIVE_URL=/s/=.*/=\"https:\/\/${NEW_SITE_NAME}.wl-staging.com\"/" cms/.env; \
		sed -i '' -e 's/8888/$(NGINX_PORT)/g' -e 's/3000/$(FRONTEND_PORT)/g' -e 's/24670/$(HMR_PORT)/g' config-files/check-front-env.sh; \
		if [ "$(front_type)" = "astro" ]; then \
				sed -i '' -e 's/3000/$(FRONTEND_PORT)/g' ./astro/astro.config.mjs; \
		fi; \
	else \
		echo "\nPorts have been already allocated.\n"; \
		echo "\tBackend on: $(shell bash -c './config-files/color-me.sh "http://localhost:$(back_port)"')"; \
		echo "\tFrontend on: $(shell bash -c './config-files/color-me.sh "http://localhost:$(front_port)"')\n"; \
	fi	

check-front-env:
	@sh ./config-files/check-front-env.sh cms

check-full-env:
	@sh ./config-files/check-front-env.sh

cleanup:
	@rm -rf config-files data db-data docker-config tmp .my.ext.cnf .my.local.cnf cms/.env $(front_type)/.env docker-compose.dev.yml $(front_type)/Dockerfile $(front_type)/yarn.lock

### RUNNING ENVIRONMENTS ###

cms: check-config set-permissions check-env get-token-cms find-port check-front-env
	@echo "\nWaiting for settings to load...\n"; \
	if [ -f "docker-compose.yml" ]; then \
		docker compose down; \
	fi; \
	if [ ! -f "docker-compose.yml" ] || ! diff -q docker-compose.yml docker-compose.dev.yml >/dev/null; then \
		ln -sf docker-compose.dev.yml docker-compose.yml; \
	fi; \
	if [ ! "$$(docker ps -q -f name=${CONTAINER})" ]; then \
		cp -n cms/example.env cms/.env; \
		docker-compose up --no-deps nginx mysql redis php queue php_xdebug --remove-orphans -d; \
		./config-files/wait-for-it.sh queue 'Finished applying changes'; \
	fi; 
	@echo "\n\tBackend URL: $(shell bash -c './config-files/color-me.sh "http://localhost:$(back_port)"')"; \
	echo "\nYou can run now $(shell bash -c './config-files/color-me.sh "make dev"')"

full: check-config set-permissions check-env get-token find-port check-full-env
	@rm -rf $(front_type)/node_modules $(front_type)/.nuxt $(front_type)/.pnpm-store
	@if [ -f "docker-compose.yml" ]; then \
		docker compose down; \
	fi; \
	if [ ! -f "docker-compose.yml" ] || ! diff -q docker-compose.yml docker-compose.dev.yml >/dev/null; then \
		ln -sf docker-compose.dev.yml docker-compose.yml; \
	fi; \
	if [ ! "$$(docker ps -q -f name=${CONTAINER})" ]; then \
		cp -n cms/example.env cms/.env; \
		docker compose up --no-deps nginx mysql redis php queue php_xdebug --remove-orphans -d; \
		echo ""; \
		./config-files/wait-for-it.sh queue 'Finished applying changes'; \
		echo ""; \
		docker compose up $(front_type) --remove-orphans --build --wait -d; \
		./config-files/wait-for-it.sh $(front_type) "$$([ "$(front_type)" = "frontend" ] && echo "Nitro" || echo "Local")"; \
	fi; 
	@echo "\n\tBackend URL: $(shell bash -c './config-files/color-me.sh "http://localhost:$(back_port)"')"; \
	echo "\tFrontend URL: $(shell bash -c './config-files/color-me.sh "http://localhost:$(front_port)"')"; 

front:
	@./config-files/check-package.sh

test-color:
	@echo "You can run now $(shell bash -c './config-files/color-me.sh "make dev"')"

test-package:
	./config-files/check-package.sh

dev:
	@./config-files/check-package.sh 

build:
	@node_v=$$(node -v); \
	echo "node version is $${node_v}"; \
	major_v=$$(echo "$${node_v}" | cut -c2- | awk -F. '{print $$1}'); \
	if [ "$${major_v}" -lt 18 ]; then \
		echo "Switching to --lts..."; \
		. ~/.nvm/nvm.sh && nvm use --lts; \
	fi; \
	cd $(front_type); \
	pnpm install; \
 	pnpm build; \
	cd ..; \
	echo "Switching to $${node_v}..."; \
		. ~/.nvm/nvm.sh && nvm use $${node_v}; 

# CONTAINERS

list_containers:
	@echo "Available containers:"
	@docker-compose ps --services | awk '{printf "%-2d.%s\n", NR, $$0}'

rebuild: list_containers
	@echo ""
	@read -p "Enter the number of the container to rebuild (or type 'all' to rebuild all): " NUM; \
	if [ "$$NUM" = "all" ]; then \
		docker-compose up --build; \
	else \
		CONTAINER=$$(docker-compose ps --services | sed -n "$$NUM p"); \
		docker-compose up --build -d "$$CONTAINER"; \
	fi

restart:
	@docker compose down
	@docker compose up nginx mysql redis php queue php_xdebug -d; \
	echo ""; \
	./config-files/wait-for-it.sh queue 'Finished applying changes'; \
	echo ""; \
	docker compose up $(front_type) -d; \
	echo ""; \
	./config-files/wait-for-it.sh $(front_type) "$$([ "$(front_type)" = "frontend" ] && echo "Nitro" || echo "Local")"; \
	echo "\nBackend URL: $(shell bash -c './config-files/color-me.sh "http://localhost:$(back_port)"')"; \
	echo "Frontend URL: $(shell bash -c './config-files/color-me.sh "http://localhost:$(front_port)"')"; \

restart-selected: list_containers
	@echo ""
	@read -p "Enter the number of the container to rebuild (or type 'all' to rebuild all): " NUM; \
	if [ "$$NUM" = "all" ]; then \
		docker-compose restart; \
	else \
		CONTAINER=$$(docker-compose ps --services | sed -n "$$NUM p"); \
		docker-compose restart "$$CONTAINER"; \
	fi
%:
	@:
# ref: https://stackoverflow.com/questions/6273608/how-to-pass-argument-to-makefile-from-command-line
