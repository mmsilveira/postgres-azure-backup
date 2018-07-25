#!/bin/bash

if [ "${POSTGRES_HOST}" = "" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

if [ -n $POSTGRES_PASSWORD ]; then
    export PGPASSWORD=$POSTGRES_PASSWORD
fi

if [[ "${LOCAL_DIR}" = "" ]]; then
    $LOCAL_DIR="/tmp"
fi

if [ "$1" == "backup" ]; then
    if [ -n "$2" ]; then
        databases=$2
    else
        databases=`psql --username=$POSTGRES_USER --host=$POSTGRES_HOST --port=$POSTGRES_PORT -l | grep "UTF8" | grep -Ev "(template[0-9]*)" | awk '{print $1}'`
    fi

    for db in $databases; do
        echo "dumping $db"

        pg_dump -v --host=$POSTGRES_HOST --port=$POSTGRES_PORT --username=$POSTGRES_USER $db | gzip > "$LOCAL_DIR/$db.gz"

        if [ $? == 0 ]; then
            yes | az storage blob upload -f $LOCAL_DIR/$db.gz -n $db_$(date -d "today" +"%Y_%m_%d_%H_%M").gz -c $AZURE_STORAGE_CONTAINER --connection-string "DefaultEndpointsProtocol=https;BlobEndpoint=https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/;AccountName=$AZURE_STORAGE_ACCOUNT;AccountKey=$AZURE_STORAGE_ACCESS_KEY"

            if [ $? == 0 ]; then
                rm $LOCAL_DIR/$db.gz
            else
                >&2 echo "couldn't transfer $db.gz to Azure"
            fi
        else
            >&2 echo "couldn't dump $db"
        fi
    done
elif [ "$1" == "restore" ]; then
    if [ -n "$2" ]; then
        archives=$2.gz
    else
        archives=`az storage blob list --account-name $AZURE_STORAGE_ACCOUNT --account-key "$AZURE_STORAGE_ACCESS_KEY" -c $AZURE_STORAGE_CONTAINER | grep ".gz" | awk '{print $2}'`
    fi

    for archive in $archives; do
        tmp=$LOCAL_DIR/$archive

        echo "restoring $archive"
        echo "...transferring"

        yes | az storage blob download  --account-name $AZURE_STORAGE_ACCOUNT --account-key "$AZURE_STORAGE_ACCESS_KEY" -c $AZURE_STORAGE_CONTAINER -f $tmp  -n $archive 

        if [ $? == 0 ]; then
            echo "...restoring"
            db=$(cut -d'_' -f1 <<< $arquive)

            psql --host=$POSTGRES_HOST --port=$POSTGRES_PORT --username=$POSTGRES_USER -d $db -c "drop schema public cascade; create schema public;"

            gunzip -c $tmp | psql --host=$POSTGRES_HOST --port=$POSTGRES_PORT --username=$POSTGRES_USER -d $db
        else
            rm $tmp
        fi
    done
else
    >&2 echo "You must provide either backup or restore to run this container"
    exit 64
fi
