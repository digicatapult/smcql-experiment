#!/bin/bash

#run from smcql home, which contains src/ 
path=$(pwd)
echo "Using test data from $path"

if [ ! -d "$path/src" ]; then
  echo "Running from incorrect directory. Please run from project home directory."
  exit
fi

echo "Creating test database..."

dbPrefix='smcql_testDB'
dropdb $dbPrefix
createdb $dbPrefix
psql $dbPrefix -f $path/conf/workload/testDB/test_schema.sql

for i in 1 2
do
    dbName=$dbPrefix'_site'$i
    dropdb $dbName
    createdb $dbName

    psql $dbName -f $path/conf/workload/testDB/test_schema.sql
    psql $dbName -c "\COPY site FROM '$path/conf/workload/testDB/$i/site.csv' WITH DELIMITER ','"
    psql $dbName -c "\COPY mineral_stock FROM '$path/conf/workload/testDB/$i/mineral_stock.csv' WITH DELIMITER ','"
    psql $dbName -c "\COPY shipments FROM '$path/conf/workload/testDB/$i/shipments.csv' WITH DELIMITER ','"
    psql $dbName -c "\COPY shipment_content FROM '$path/conf/workload/testDB/$i/shipment_content.csv' WITH DELIMITER ','"

    # Now simulate the out-of-band agreements do the preprocessing on
    # data that is public and has been disclosed between the entities
    psql $dbName -f $path/conf/workload/testDB/setup_test_registries.sql
done

psql -lqt | cut -d \| -f 1 | grep -qw $dbPrefix
res0=$?
psql -lqt | cut -d \| -f 1 | grep -qw $dbPrefix'_site1'
res1=$?
psql -lqt | cut -d \| -f 1 | grep -qw $dbPrefix'_site2'
res2=$?

if (($res0 == 0)) && (($res1 == 0)) && (($res2 == 0)); then
    exit 0
else
    exit 1
fi
