#!/usr/bin/env bash

[ -z "$AWS_REGION" ] && [ ! -z "$INPUT_AWS_REGION" ] &&\
    AWS_REGION="$INPUT_AWS_REGION"

[ -z "$AWS_ACCESS_KEY_ID" ] && [ ! -z "$INPUT_AWS_ACCESS_KEY_ID" ] &&\ 
    AWS_ACCESS_KEY_ID="$INPUT_AWS_ACCESS_KEY_ID"

[ -z "$AWS_SECRET_ACCESS_KEY" ] && [ ! -z "$INPUT_AWS_SECRET_ACCESS_KEY" ] &&\ 
    AWS_SECRET_ACCESS_KEY="$INPUT_AWS_SECRET_ACCESS_KEY"

INITIAL_DIR=$(pwd)

DATABASES=${DATABASES:-$1}
[ -z "$DATABASES" ] && echo '$DATABASES Not set' && exit 1

mkdir -p .drone/databases
cd .drone/databases
echo "
[mysql]
user = $INPUT_MYSQL_USER
host = $INPUT_MYSQL_HOST
" > .my.cnf

[ ! -z "$INPUT_MYSQL_PASS" ] && echo "pass = $INPUT_MYSQL_PASS" >> .my.cnf
[ ! -z "$INPUT_MYSQL_PORT" ] && echo "port = $INPUT_MYSQL_PORT" >> .my.cnf


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

