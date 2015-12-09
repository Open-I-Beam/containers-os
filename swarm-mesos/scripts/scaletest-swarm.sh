#!/bin/bash
# Simple script to test swarm scalability by sequentially starting containers.

CURR_DIR=$(cd $(dirname $0) && pwd)
source $CURR_DIR/env.rc

# Define a timestamp function
timestamp() {
   date +"%s%3N"
}

DOCKER="docker -H $MANAGER_IP:$MANAGER_PORT"

if [ -z "$1" ]; then
  echo "usage: $0 <command> "
  echo "    where: <command> = run | clean"
  exit
fi

if [ $1 = 'run' ]; then
  for (( i=1; i<=$MAX_CONTAINERS; i++ ))
  do
    container=cont$i

    port=$((10000+$i))
    tstart=$(timestamp)
    echo "running >> $DOCKER run --name $container -tid -m 12m -p $port:3000 busybox httpd -f -p 3000"
    $DOCKER run --name $container -tid -m 12m -p $port:3000 busybox httpd -f -p 3000
    tlaunched="$(($(timestamp)-$tstart))"

    #wait until running state
    tstart=$(timestamp)
    k=0
    skip="false"
    echo "waiting for container $container to start"
    while [ "$($DOCKER inspect -f {{.State.Running}} $container)" != 'true' ]
    do
      sleep 0.01
      if [ $k -gt 100 ]; then
        skip="true"
        break;
      fi
      k=$((k+1))
    done
    trun="$(($(timestamp)-$tstart))"

    if [ $skip = "true" ]; then
	     echo "Container $container did not start ... skipping to next container"
	     continue
    fi

    # now test connectivity
    host=$($DOCKER inspect -f {{.Node.IP}} $container)

    if [ -z "${host// }" ]; then
       echo "command to get host failed... skipping ..."
       continue
    fi

    echo "testing connectivity on:  $host:$port"
    tstart=$(timestamp)
    while ! echo exit | nc $host $port; do sleep 0.01; done
    tconnect="$(($(timestamp)-$tstart))"

    echo $t1 $i 0 $tlaunched $trun $tconnect
    echo $t1 $i 0 $tlaunched $trun $tconnect >> $CURR_DIR/$FILE
  done
fi

if [ $1 = 'clean' ]; then
  for (( i=1; i<=$MAX_CONTAINERS; i++ ))
  do
    container=cont$i
    $DOCKER rm -f $container
  done
fi
