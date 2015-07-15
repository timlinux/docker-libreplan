#!/bin/bash

export PGHOST="$DB_PORT_5432_TCP_ADDR"
export PGPORT="$DB_PORT_5432_TCP_PORT"
export PGPASSWORD="$DB_ENV_POSTGRES_PASSWORD"
export PGUSER=postgres

polling_interval=3
echo "wait for postgres to start first..."

# wait until the database is running
until nc -z $PGHOST $PGPORT
do
  echo "waiting for $polling_interval seconds..."
  sleep $polling_interval
done

if [[ ! `psql -lqt | grep '^ libreplan\b'` ]]; then
  echo "CREATE DATABASE libreplan;\
    CREATE USER libreplan WITH PASSWORD 'libreplan';\
    GRANT ALL PRIVILEGES ON DATABASE libreplan TO libreplan;" | psql;

  wget -q -O install.sql http://downloads.sourceforge.net/project/libreplan/LibrePlan/install_1.4.0.sql
  PGPASSWORD=libreplan psql -U libreplan -f install.sql;
fi

catalina.sh run
