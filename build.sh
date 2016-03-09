#!/usr/bin/env bash

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
source $SCRIPTDIR/conf.sh

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

while getopts ":hpr" opt; do
  case $opt in
    p)
      print="True"
      ;;
    r)
      ${sudo} docker rmi -f $IMAGENAME 2> /dev/null || true
      ;;
    *)
      echo "usage: $0 [-h] [-i] [-p] [-r] [cmd]
   -h  print this help text
   -p  print docker build command on stdout
   -r  remove existing image $IMAGENAME (-f)
   "
      exit 0
      ;;
  esac
done

shift $((OPTIND-1))

docker_exec="docker build $BUILDARGS -t=$IMAGENAME ."
if [ "$print" = "True" ]; then
    echo $docker_exec
fi

${sudo} $docker_exec
