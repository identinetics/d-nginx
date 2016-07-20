#!/usr/bin/env bash


while getopts ":hn:" opt; do
  case $opt in
    n)
      config_nr=$OPTARG
      re='^[0-9][0-9]$'
      if ! [[ $OPTARG =~ $re ]] ; then
         echo "error: -n argument is not a number in the range frmom 02 .. 99" >&2; exit 1
      fi
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      exit 1
      ;;
    *)
      echo "usage: $0 [-h] [-n]
   -h  print this help text
   -n  configuration number ('<NN>' in conf<NN>.sh)

   Reload nginx configuration
   "
      exit 0
      ;;
  esac
done

shift $((OPTIND-1))

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
source $SCRIPTDIR/conf${config_nr}.sh


if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi
${sudo} docker kill -s HUP $CONTAINERNAME