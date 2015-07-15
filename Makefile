PROJECT_ID := libreplan

SHELL := /bin/bash

# ----------------------------------------------------------------------------
#    P R O D U C T I O N     C O M M A N D S
# ----------------------------------------------------------------------------
default: web
run: build permissions web 

deploy: run
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Bringing up fresh instance "
	@echo "You can access it on http://localhost:8888"
	@echo "------------------------------------------------------------------"

build:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Building in production mode"
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) build

web:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Running in production mode"
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) up -d libreplan
	@# Dont confuse this with the dbbackup make command below
	@# This one runs the postgis-backup cron container
	@# We add --no-recreate so that it does not destroy & recreate the db container
	@docker-compose -p $(PROJECT_ID) up --no-recreate --no-deps -d dbbackups

permissions:
	# Probably we want something more granular here....
	# Your sudo password will be needed to set the file permissions
	# on logs, media, static and pg dirs
	@if [ ! -d "logs" ]; then mkdir logs; fi
	#@if [ ! -d "media" ]; then mkdir media; fi
	#@if [ ! -d "static" ]; then mkdir static; fi
	@if [ ! -d "backups" ]; then mkdir backups; fi
	@if [ -d "logs" ]; then sudo chmod -R a+rwx logs; fi
	#@if [ -d "media" ]; then sudo chmod -R a+rwx media; fi
	#@if [ -d "static" ]; then sudo chmod -R a+rwx static; fi
	@if [ -d "pg" ]; then sudo chmod -R a+rwx pg; fi
	@if [ -d "backups" ]; then sudo chmod -R a+rwx backups; fi

db:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Running db in production mode"
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) up -d db

kill:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Killing in production mode"
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) kill

rm: kill
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Removing production instance!!! "
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) rm

logs:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Showing libreplan logs in production mode"
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) libreplan

dblogs:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Showing db logs in production mode"
	@echo "------------------------------------------------------------------"
	@docker-compose -p $(PROJECT_ID) logs db

shell:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Shelling in in production mode"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_libreplan_1 /bin/bash

dbshell:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Shelling in in production database"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_db_1 psql -U docker -h localhost gis

dbrestore:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Restore dump from backups/latest.dmp in production mode"
	@echo "------------------------------------------------------------------"
	@# - prefix causes command to continue even if it fails
	-@docker exec -t -i $(PROJECT_ID)_db_1 su - postgres -c "dropdb gis"
	@docker exec -t -i $(PROJECT_ID)_db_1 su - postgres -c "createdb -O docker -T template_postgis gis"
	@docker exec -t -i $(PROJECT_ID)_db_1 pg_restore /backups/latest.dmp | docker exec -i $(PROJECT_ID)_db_1 su - postgres -c "psql gis"

dbbackup:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Create `date +%d-%B-%Y`.dmp in production mode"
	@echo "------------------------------------------------------------------"
	@# - prefix causes command to continue even if it fails
	@docker exec -t -i $(PROJECT_ID)_dbbackups_1 /backups.sh
	@docker exec -t -i $(PROJECT_ID)_dbbackups_1 cat /var/log/cron.log | tail -2 | head -1 | awk '{print $4}'
	-@if [ ! -f "backups/latest.dmp" ]; then ln -s backups/`date +%Y`/`date +%B`/PG_$(PROJECT_ID)_`date +%d-%B-%Y`.dmp backups/latest.dmp; fi
	@echo "Backup should be at: backups/`date +%Y`/`date +%B`/PG_$(PROJECT_ID)_`date +%d-%B-%Y`.dmp"

maillogs:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Showing smtp logs in production mode"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_smtp_1 tail -f /var/log/mail.log

mailerrorlogs:
	@echo
	@echo "------------------------------------------------------------------"
	@echo "Showing smtp error logs in production mode"
	@echo "------------------------------------------------------------------"
	@docker exec -t -i $(PROJECT_ID)_smtp_1 tail -f /var/log/mail.err

