#!/usr/bin/env bash

INITIAL_DIR=$(pwd)

DATABASES=${DATABASES:-$1}
[ -z "$DATABASES" ] && echo '$DATABASES Not set' && exit 1

mkdir -p .drone/databases
cd .drone/databases
echo "
[mysql]
user = $MYSQL_USER
host = $MYSQL_HOST
" > .my.cnf

[ ! -z "$MYSQL_PASS" ] && echo "pass = $MYSQL_PASS" >> .my.cnf
[ ! -z "$MYSQL_PORT" ] && echo "port = $MYSQL_PORT" >> .my.cnf


MYSQL="mysql --defaults-file=.my.cnf"

for DB in $DATABASES
do 
    aws s3 cp s3://spear-backup/schemas/$DB.latest.sql.gz ./; 
done

# Wait for MySQL to start"
i=0; while [ $((i+1)) -lt 30 ] && [ ! $($MYSQL -Nse "SELECT VERSION();") ]
do
    echo "Waiting for MySQL... $i"
    sleep 1; 
done

for DB in $DATABASES
do 
    DB_TDD="$DB"_tdd
    echo "Dropping $DB_TDD"
    $MYSQL -e "DROP DATABASE IF EXISTS $DB_TDD; CREATE DATABASE $DB_TDD;"
done

for DB in $DATABASES
do 
    DB_TDD="$DB"_tdd
    echo "Importing $DB_TDD"
    gunzip -c $DB.latest.sql.gz | $MYSQL $DB_TDD
done

cd $INITIAL_DIR
exit 0

