#!/bin/bash

if [[ "$(basename $(pwd))" != "smcql-experiment" ]]
then
    echo "Please run from repo root"
    echo "Usage: ./scripts/stop.sh [remote|local]"
    exit 1
fi

if [ $# -eq 0 ]
then
    echo "Usage: ./scripts/stop.sh [remote|local]"
    exit 1
fi

if [ "$1" = "local" ]
then
    docker-compose -f ./docker/docker-compose-local.yml down
elif [ "$1" = "remote" ]
then
    docker-compose -f ./docker/docker-compose-remote.yml down
else
    echo "Usage: ./scripts/stop.sh [remote|local]"
    exit 1
fi
