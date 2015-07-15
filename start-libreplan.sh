#!/bin/bash

export PGHOST="$DB_PORT_5432_TCP_ADDR"
export PGPORT="$DB_PORT_5432_TCP_PORT"
export PGPASSWORD="docker"
export PGUSER=docker

polling_interval=3
echo "wait for postgres to start first..."

# wait until the database is running
until nc -z $PGHOST $PGPORT
do
  echo "waiting for $polling_interval seconds..."
  sleep $polling_interval
done

if [[ ! `psql -lqt | grep '^ libreplan\b'` ]]; then
  echo "CREATE DATABASE gis;\
    GRANT ALL PRIVILEGES ON DATABASE docker TO docker;" | psql;

  wget -q -O install.sql http://downloads.sourceforge.net/project/libreplan/LibrePlan/install_1.4.0.sql
  PGPASSWORD=docker psql -U docker -f install.sql gis;
fi

catalina.sh run
