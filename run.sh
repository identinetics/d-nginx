#!/usr/bin/env bash

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
source $SCRIPTDIR/conf.sh

export CONTAINERNAME='nginx1'
export HOSTVOLROOT="/docker_volumes/$CONTAINERNAME"
useropt="-u $CONTAINERUSER"

runopt='-d --restart=unless-stopped'

while getopts ":ir" opt; do
  case $opt in
    i)
      echo "starting docker container in interactive mode"
      runopt='-it --rm'
      docker rm $CONTAINERNAME 2>/dev/null
      ;;
    r)
      echo "container user is root"
      useropt='-u 0'
      ;;
  esac
done

shift $((OPTIND-1))


if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi
${sudo} docker rm -f $CONTAINERNAME 2>/dev/null || true
${sudo} docker run $runopt $useropt \
    --hostname=$CONTAINERNAME \
    --name=$CONTAINERNAME \
    --net=$INTERCONTAINER_NETWORK \
    $ENVSETTING \
    $PORTMAPING \
    $VOLMAPPING \
    $IMAGENAME $@