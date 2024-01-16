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

psql -lqt | cut -d \| -f 1 | grep -qw $dbPrefix
exit $?
