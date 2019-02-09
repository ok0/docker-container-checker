#!/bin/bash

# PUT container name
CONTAINER=$1

if [ "${CONTAINER}" == "" ]; then
	echo "PUT CONTAINER NAME."
	exit 1
fi

# PUT POST_URL
POST_URL=$2
if [ "${POST_URL}" == "" ]; then
	echo "PUT POST_URL."
	exit 1
fi

CONTAINER_PS=($(docker ps -a | grep $CONTAINER 2> /dev/null))
CONTAINER_CID=${CONTAINER_PS[0]}
if [ "${CONTAINER_CID}" == "" ]; then
	echo "Cant't find CONTAINER ID using $CONTAINER."
	exit 1
fi

RUNNING_STATE=$(docker inspect --format="{{.State.Running}}" $CONTAINER_CID 2> /dev/null)
RESTARTING_STATE=$(docker inspect --format="{{.State.Restarting}}" $CONTAINER_CID)

if [ "$RESTARTING_STATE" == "true" ]; then
	echo "$CONTAINER IS RESTARTING."
	curl -X POST -d "dockerName=$CONTAINER&state=restarting" $POST_URL
	exit 2
fi

if [ "$RUNNING_STATE" == "false" ]; then
	if [ "$RESTARTING_STATE" == "false" ]; then
		echo "$CONTAINER IS NOT RUNNING!"
		curl -X POST -d "dockerName=$CONTAINER&state=not_running" $POST_URL
		docker stop $CONTAINER && docker start $CONTAINER
		exit 1
	fi
fi

SEARCHD_STATUS=$(mysql -h0 -P9306 myql -Bse "SELECT NOW()" 2>&1)
if [[ "$SEARCHD_STATUS" = *"ERROR"* ]]; then
        echo "Can't connect to searchd"
        curl -X POST -d "dockerName=$CONTAINER&state=connect_to_searchd" $POST_URL
        docker exec -d $CONTAINER bash -c "searchd"
        exit 1
fi


echo "CONTAINER" $CONTAINER
echo "RUNNING_STATE" $RUNNING_STATE
echo "RESTARTING_STATE" $RESTARTING_STATE
