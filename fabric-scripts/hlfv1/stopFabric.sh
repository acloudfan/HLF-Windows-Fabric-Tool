#!/bin/bash

# Exit on first error, print all commands.
set -ev

#Detect architecture
ARCH=`uname -m`

# Grab the current directorydirectory.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Shut down the Docker containers that might be currently running.
cd "${DIR}"/composer

#Changed - raj@acloudfan.com - takes care of the path
#Added the variable
COMPOSE_FILE="$(cygpath -pw "$DIR/composer/docker-compose.yml")"
#ARCH=$ARCH docker-compose -f "${DIR}"/composer/docker-compose.yml stop
ARCH=$ARCH docker-compose -f $COMPOSE_FILE stop
