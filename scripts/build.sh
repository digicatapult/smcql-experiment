#!/bin/bash

if [[ "$(basename $(pwd))" != "smcql-experiment" ]]
then
    echo "Please run from repo root"
    exit 1
fi

if [ -z ./smcql-experiment/dependencies/smcql/setup.sh ]
then
    echo "Please run 'git submodule update --init --recursive' and then run this script again"
    exit 1
fi

echo "Building docker containers..."
docker build --file ./docker/Dockerfile --progress plain -t "smcql" .
docker build --file ./docker/Dockerfile.remote --progress plain -t "smcql_remote" .

echo "Done."
