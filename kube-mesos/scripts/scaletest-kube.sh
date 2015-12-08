#!/bin/bash

CURR_DIR=$(cd $(dirname $0) && pwd)
source $CURR_DIR/env.rc

# Define a timestamp function
timestamp() {
   date +"%s%3N"
}

gen_ip(){
  i=$1
  j=$((i / 256 ))
  k=$((i - 256*j))
  echo 192.168.$j.$k
}

#rm $CURR_DIR/$FILE

KUBECTL="kubectl --server $MANAGER_IP:$KUBE_PORT"

if [ -z "$1" ]; then
  echo "usage: $0 <command> "
  echo "    where: <command> = run | clean"
  exit
fi

if [ $1 = 'run' ]; then
  rm -f $CURR_DIR/$FILE
  mkdir -p $CURR_DIR/data
  touch $CURR_DIR/$FILE
  for (( i=1; i<=$MAX_CONTAINERS; i++ )) 
  do
    container=cont$i
  
    t1=$(timestamp) 
    tstart=$t1 
    # we do not use profiles here
    tprof="$(($(timestamp)-$tstart))"

    tstart=$(timestamp)
    $KUBECTL run $container --image=busybox --limits="cpu=50m,memory=32Mi" --port=3000 --command -- httpd -f -p 3000
    tlaunched="$(($(timestamp)-$tstart))"     
   
    #wait until running state
    tstart=$(timestamp)
    while : ; do
      info=$($KUBECTL describe pod $container)
      result=$(echo "$info" | grep Status:)
      if [[ $result == *"Running"* ]]; then
        break
      fi
      sleep 0.5
    done
    trun="$(($(timestamp)-$tstart))"   

    # get IP for container and host 
    container_ip=$(echo "$info" | grep IP: | awk '{print $2}')
    hosts=$(echo "$info" | grep Node: | awk '{print $2}')
    IFS='/' read -a array <<< "${hosts}"
    host="${array[0]}"

    # now test connectivity
    tstart=$(timestamp)
    ssh $host "while ! echo exit | nc $container_ip 3000; do sleep 0.01; done"
    tping="$(($(timestamp)-$tstart))"

    echo $t1 $i $tprof $tlaunched $trun $tping

    echo $t1 $i $tprof $tlaunched $trun $tping >> $CURR_DIR/$FILE 
  done
fi

if [ $1 = 'clean' ]; then
  for (( i=1; i<=$MAX_CONTAINERS; i++ ))
  do
    container=cont$i
    $KUBECTL delete rc $container
    sleep 1
  done
fi
 


