#!/bin/bash

if [[ "$(basename $(pwd))" != "smcql-experiment" ]]
then
    echo "Please run from repo root"
    exit 1
fi

echo "Cloning SCMQL..."
cd dependencies && rm -rf smcql 2>/dev/null && git clone https://github.com/smcql/smcql.git && cd smcql && git apply ../smcql-fixes.diff && cd ../..

echo "Building docker containers..."
docker build --file ./docker/Dockerfile --progress plain -t "smcql" .
docker build --file ./docker/Dockerfile.remote --progress plain -t "smcql_remote" .

echo "Done."
