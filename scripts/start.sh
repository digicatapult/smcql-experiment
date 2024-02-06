#!/bin/bash

if [[ "$(basename $(pwd))" != "smcql-experiment" ]]
then
    echo "Please run from repo root"
    echo "Usage: ./scripts/start.sh [remote|local]"
    exit 1
fi

if [[ "$1" != "local" && "$1" != "remote" ]]
then
    echo "Usage: ./scripts/start.sh [remote|local]"
    exit 1
fi

if [[ -z "$(docker images -q smcql 2> /dev/null)" || \
          -z "$(docker images -q smcql_remote 2> /dev/null)" ]]
then
   ./scripts/build.sh
fi

if [ "$1" = "local" ]
then
    docker-compose -f ./docker/docker-compose-local.yml up -d

    # Use custom config mounted in docker-compose
    docker exec smcql_local bash -c 'mv /home/smcql/smcql/conf /home/smcql/smcql/conf-old'
    docker exec smcql_local ln -s /home/smcql/sample-conf /home/smcql/smcql/conf

    # Start database server
    docker exec smcql_local sudo service postgresql start

    # Run SMCQL setup
    docker exec smcql_local ./setup.sh
elif [ "$1" = "remote" ]
then
    docker-compose -f ./docker/docker-compose-remote.yml up -d
    for i in 1 2
    do
        docker exec smcql_site$i ln -s /home/smcql/sample-conf /home/smcql/smcql/conf
    
        # Set up SSH keys
        docker exec smcql_site$i sudo service ssh start
        docker exec -u smcql smcql_broker sshpass -p smcql ssh-copy-id 172.123.0.1$i

        # Start database server
        docker exec smcql_site$i sudo service postgresql start

        # Run SMCQL setup
        docker exec smcql_site$i ./setup.sh
    done
        
    docker exec smcql_broker bash -c 'mv /home/smcql/smcql/conf /home/smcql/smcql/conf-old'
    docker exec smcql_broker ln -s /home/smcql/sample-conf /home/smcql/smcql/conf

    # Start database server
    docker exec smcql_broker sudo service postgresql start
    
    # Run SMCQL setup
    docker exec smcql_broker ./setup.sh
else
    exit 1
fi
