#!/bin/bash

#run from smcql home, which contains src/ 
path=$(pwd)
echo "Using test data from $path"

echo "Creating test database..."

i=1
dbName="smcql_testDB_site$i"
dropdb $dbName
createdb $dbName

psql $dbName -f $path/conf/workload/testDB/test_schema.sql
psql $dbName -c "\COPY site FROM '$path/conf/workload/testDB/$i/site.csv' WITH DELIMITER ','"
psql $dbName -c "\COPY mineral_stock FROM '$path/conf/workload/testDB/$i/mineral_stock.csv' WITH DELIMITER ','"
psql $dbName -c "\COPY shipments FROM '$path/conf/workload/testDB/$i/shipments.csv' WITH DELIMITER ','"
psql $dbName -c "\COPY shipment_content FROM '$path/conf/workload/testDB/$i/shipment_content.csv' WITH DELIMITER ','"

psql $dbName -f $path/conf/workload/testDB/setup_test_registries.sql

psql -lqt | cut -d \| -f 1 | grep -qw $dbName
exit $?
