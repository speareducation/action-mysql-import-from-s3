#!/usr/bin/env bash

INITIAL_DIR=$(pwd)

[ -z "$INPUT_DATABASES" ] && echo '$INPUT_DATABASES Not set' && exit 1

mkdir .mysql-import-from-s3 && cd .mysql-import-from-s3

echo "
[mysql]
user = $INPUT_MYSQL_USER
host = $INPUT_MYSQL_HOST
" > .my.cnf

[ ! -z "$INPUT_MYSQL_PASS" ] && echo "pass = $INPUT_MYSQL_PASS" >> .my.cnf
[ ! -z "$INPUT_MYSQL_PORT" ] && echo "port = $INPUT_MYSQL_PORT" >> .my.cnf

MYSQL="mysql --defaults-file=.my.cnf"

# Wait for MySQL to start"
i=0; while [ $((i+1)) -lt 30 ] && [ ! $($MYSQL -Nse "SELECT VERSION();") ]
do
    echo "Waiting for MySQL... $i"
    sleep 1;
done
[ "$i" == "30" ] && echo "Failed to connect to mysql." && exit 1

for ENTRY in $(echo "$INPUT_DATABASES" | jq -c .[])
do
    db=$(echo "$ENTRY" | jq -r .db)
    s3Uri=$(echo "$ENTRY" | jq -r .s3Uri)
    dumpFile=$(basename "$s3Uri")
    aws s3 cp "$s3Uri" "./$dumpFile"
    [ ! -f "$dumpFile" ] && echo "Failed to download $dumpFile" && exit 1

    echo "Creating $db"
    $MYSQL -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;" || exit 1
    
    echo "Importing $db from file '${dumpFile}'"
    if [[ "$dumpFile" == *.gz ]]
    then
        gunzip -c "$dumpFile" | $MYSQL $db
    else
        cat "$dumpFile" | $MYSQL $db
    fi
done
echo "Cleaning up .mysql-import-from-s3 dir..."
rm -rf .mysql-import-from-s3
exit 0
