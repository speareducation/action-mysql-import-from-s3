#!/usr/bin/env bash

INITIAL_DIR=$(pwd)

[ -z "$INPUT_DATABASES" ] && echo '$INPUT_DATABASES Not set' && exit 1

S3_IMPORTS_DIR=/tmp/.mysql-import-from-s3

if [[ -n "$INPUT_BASE_REF" ]]
then

    mkdir -p ${S3_IMPORTS_DIR}
    cd ${S3_IMPORTS_DIR}

    echo '[mysql]' > .my.cnf
    echo "user = $INPUT_MYSQL_USER" >> .my.cnf
    echo "host = $INPUT_MYSQL_HOST" >> .my.cnf
    [ ! -z "$INPUT_MYSQL_PASS" ] && echo "pass = $INPUT_MYSQL_PASS" >> .my.cnf
    [ ! -z "$INPUT_MYSQL_PORT" ] && echo "port = $INPUT_MYSQL_PORT" >> .my.cnf

    MYSQLDUMP="mysqldump --defaults-file=.my.cnf"

    for dbName in $INPUT_DATABASES
    do
        tddDbName="${dbName}_tdd"
        dumpFile="./${dbName}.sql"

        echo "Exporting schema dump for $dbName"
        $MYSQLDUMP --no-create-db --no-data --ignore-table="$tddDbName.migrations" "$tddDbName" > $dumpFile || continue
        [[ ! -s "$dumpFile" ]] && echo "ERROR: $dumpFile is empty!" && continue

        $MYSQLDUMP --no-create-db "$tddDbName" "migrations" 2>/dev/null >> $dumpFile

        # reset auto increments
        sed 's|AUTO_INCREMENT=[0-9]*|AUTO_INCREMENT=0|g' $dumpFile
        gzip $dumpFile

        aws s3 cp "$dumpFile.gz" "s3://$INPUT_S3_BUCKET/schemas/branches/$INPUT_BASE_REF/$dbName.sql.gz"
    done

    cd ${INITIAL_DIR}
fi

echo "Cleaning up mysql imports dir ${S3_IMPORTS_DIR}..."
rm -rf ${S3_IMPORTS_DIR}
exit 0
