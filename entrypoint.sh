#!/usr/bin/env bash

INITIAL_DIR=$(pwd)

[ -z "$INPUT_DATABASES" ] && echo '$INPUT_DATABASES Not set' && exit 1

S3_IMPORTS_DIR=/tmp/.mysql-import-from-s3
mkdir -p ${S3_IMPORTS_DIR}
cd ${S3_IMPORTS_DIR}

cat << EOF > .my.cnf
[mysql]
user = $INPUT_MYSQL_USER
host = $INPUT_MYSQL_HOST
EOF

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

for dbName in $INPUT_DATABASES
do
    tddDbName="${dbName}_tdd"
    dumpFile="./$dbName.sql.gz"

    echo "Downloading schema dump for $dbName"

    # Attempt to download and import schema branch file
    if [[ -n "$INPUT_BASE_REF" ]]
    then
        branchDumpFile="./$dbName.branch.sql.gz"
        echo "Trying s3://$INPUT_S3_BUCKET/aurora/schemas/branches/$INPUT_BASE_REF/$dbName.sql.gz" && \
        aws s3 cp "s3://$INPUT_S3_BUCKET/aurora/schemas/branches/$INPUT_BASE_REF/$dbName.sql.gz" "$branchDumpFile" 2>/dev/null
        if [[ -f "$branchDumpFile" ]]
        then
            errorOutput=$(mktemp)
            echo "Creating $tddDbName"
            $MYSQL -e "DROP DATABASE IF EXISTS $tddDbName; CREATE DATABASE $tddDbName;" || exit 1

            echo "Importing $tddDbName from file '$branchDumpFile'"
            gunzip -c "$branchDumpFile" | $MYSQL $tddDbName && continue # if successful, continue to next database

            echo "Branch import failed. Trying default."
        fi
    fi

    echo "Trying s3://$INPUT_S3_BUCKET/aurora/schemas/$dbName.schema.latest.sql.gz" && \
    aws s3 cp "s3://$INPUT_S3_BUCKET/aurora/schemas/$dbName.schema.latest.sql.gz" "$dumpFile"
    
    [[ ! -f "$dumpFile" ]] && echo "Failed to download $dumpFile" && exit 1

    echo "Creating $tddDbName"
    $MYSQL -e "DROP DATABASE IF EXISTS $tddDbName; CREATE DATABASE $tddDbName;" || exit 1
    
    echo "Importing $tddDbName from file '$dumpFile'"
    gunzip -c "$dumpFile" | $MYSQL $tddDbName
done

echo "Cleaning up mysql imports dir ${S3_IMPORTS_DIR}..."
rm -rf ${S3_IMPORTS_DIR}

exit 0
