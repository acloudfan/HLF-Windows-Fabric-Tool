#!/bin/bash
echo "Development only script for Hyperledger Fabric control"

start_fabric() {
    #Detect architecture
    ARCH=`uname -m`

    cd ./fabric-scripts/hlfv11/composer
    ARCH=$ARCH docker-compose up -d
    echo
    echo 'Fabric DEV environment started'
}

stop_fabric() {
    cd ./fabric-scripts/hlfv11/composer
    docker-compose stop
    echo
    echo 'Fabric DEV environment stopped - DO NOT Clean the containers :)'
}

case $1 in 
    start)
        start_fabric
        ;;
    stop)
        stop_fabric
        ;;
    *)
        echo 'Usage: ./fabricUtil start | stop'
esac
