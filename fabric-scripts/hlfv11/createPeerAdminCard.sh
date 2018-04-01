#!/bin/bash
#- v - April 1st, 2018
echo "Windows Fabric Tool "

Usage() {
	echo ""
	echo "Usage: ./createPeerAdminCard.sh [-h host] [-n]"
	echo ""
	echo "Options:"
	echo -e "\t-h or --host:\t\t(Optional) name of the host to specify in the connection profile"
	echo -e "\t-n or --noimport:\t(Optional) don't import into card store"
	echo ""
	echo "Example: ./createPeerAdminCard.sh"
	echo ""
	exit 1
}

Parse_Arguments() {
	while [ $# -gt 0 ]; do
		case $1 in
			--help)
				HELPINFO=true
				;;
			--host | -h)
                shift
				HOST="$1"
				;;
            --noimport | -n)
				NOIMPORT=true
				;;
		esac
		shift
	done
}

# Change made by Raj
# HOST=localhost
if [[ ! -v DOCKER_HOST ]]; then
    echo "DOCKER_HOST is NOT set <<<< Please set the env for Docker !!!!"
    DOCKER_IP="localhost"
else
    
    DOCKER_IP="${DOCKER_HOST:6}"
    INDEX=`expr index "${DOCKER_IP}" :`
    echo $INDEX
    DOCKER_IP="${DOCKER_IP:0:(INDEX-1)}"
fi
echo  "Using the Docker VM IP Address: ${DOCKER_IP}"
HOST=$DOCKER_IP

Parse_Arguments $@

if [ "${HELPINFO}" == "true" ]; then
    Usage
fi

# Grab the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CYGDIR="$(cygpath -pw "$DIR")"

if [ -z "${HL_COMPOSER_CLI}" ]; then
  HL_COMPOSER_CLI=$(which composer)
fi

echo
# check that the composer command exists at a version >v0.16
COMPOSER_VERSION=$("${HL_COMPOSER_CLI}" --version 2>/dev/null)
COMPOSER_RC=$?

if [ $COMPOSER_RC -eq 0 ]; then
    AWKRET=$(echo $COMPOSER_VERSION | awk -F. '{if ($2<19) print "1"; else print "0";}')
    if [ $AWKRET -eq 1 ]; then
        echo Cannot use $COMPOSER_VERSION version of composer with this level of fabric
        exit 1
    else
        echo Using composer-cli at $COMPOSER_VERSION
    fi
else
    echo 'Need to have composer-cli installed at v0.19 or greater'
    exit 1
fi

#Changed by Raj
mkdir -p $DIR/temp;
#cat << EOF > DevServer_connection.json
cat << EOF > DevServer_connection.json
{
    "name": "hlfv1",
    "x-type": "hlfv1",
    "x-commitTimeout": 300,
    "version": "1.0.0",
    "client": {
        "organization": "Org1",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "composerchannel": {
            "orderers": [
                "orderer.example.com"
            ],
            "peers": {
                "peer0.org1.example.com": {}
            }
        }
    },
    "organizations": {
        "Org1": {
            "mspid": "Org1MSP",
            "peers": [
                "peer0.org1.example.com"
            ],
            "certificateAuthorities": [
                "ca.org1.example.com"
            ]
        }
    },
    "orderers": {
        "orderer.example.com": {
            "url": "grpc://${HOST}:7050"
        }
    },
    "peers": {
        "peer0.org1.example.com": {
            "url": "grpc://${HOST}:7051",
            "eventUrl": "grpc://${HOST}:7053"
        }
    },
    "certificateAuthorities": {
        "ca.org1.example.com": {
            "url": "http://${HOST}:7054",
            "caName": "ca.org1.example.com"
        }
    }
}
EOF

PRIVATE_KEY="${DIR}"/composer/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk
CERT="${DIR}"/composer/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem
# Changed by Raj to take care of the paths
PRIVATE_KEY="$(cygpath -pw "$PRIVATE_KEY")"
CERT="$(cygpath -pw "$CERT")"

if [ "${NOIMPORT}" != "true" ]; then
   # Changed by Raj
   # CARDOUTPUT=/tmp/PeerAdmin@hlfv1.card
    CARDOUTPUT=$CYGDIR/temp/PeerAdmin@hlfv1.card
else
    CARDOUTPUT=PeerAdmin@hlfv1.card
fi
# Chnged by Raj
#"${HL_COMPOSER_CLI}"  card create -p DevServer_connection.json -u PeerAdmin -c "${CERT}" -k "${PRIVATE_KEY}" -r PeerAdmin -r ChannelAdmin --file $CARDOUTPUT
"${HL_COMPOSER_CLI}"  card create -p DevServer_connection.json -u PeerAdmin -c "${CERT}" -k "${PRIVATE_KEY}" -r PeerAdmin -r ChannelAdmin --file $CARDOUTPUT

if [ "${NOIMPORT}" != "true" ]; then
    if "${HL_COMPOSER_CLI}"  card list -c PeerAdmin@hlfv1 > /dev/null; then
        "${HL_COMPOSER_CLI}"  card delete -c PeerAdmin@hlfv1
    fi
# Changed by Raj
#    "${HL_COMPOSER_CLI}"  card import --file /tmp/PeerAdmin@hlfv1.card 
    "${HL_COMPOSER_CLI}"  card import --file $CYGDIR/temp/PeerAdmin@hlfv1.card
    "${HL_COMPOSER_CLI}"  card list
    echo "Hyperledger Composer PeerAdmin card has been imported, host of fabric specified as '${HOST}'"

# Changed by Raj    
    #rm /tmp/PeerAdmin@hlfv1.card
    rm $CYGDIR/temp/PeerAdmin@hlfv1.card
else
    echo "Hyperledger Composer PeerAdmin card has been created, host of fabric specified as '${HOST}'"
fi
