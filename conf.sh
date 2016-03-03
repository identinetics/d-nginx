#!/usr/bin/env bash

# create dir with given user if not existing, relative to $HOSTVOLROOT; set/repair ownership
function chkdir {
    dir=$1
    user=$2
    mkdir -p "$HOSTVOLROOT/$dir"
    chown -R $user:$user "$HOSTVOLROOT/$dir"
}

# configure container
export CONTAINERNAME='nginx1'
export HOSTVOLROOT="/docker_volumes/$CONTAINERNAME"  # container volumes on docker host
export IMAGENAME='rhoerbe/nginx'
export INTERCONTAINER_NETWORK='http_proxy'
export CONTAINERUSER='nginx1'   # group and user to run container
export CONTAINERUID='8004'   # gid and uid for CONTAINERUSER
export ENVSETTING=''
export PORTMAPPING='-p 80:8080 -p 443:8443'
export VOLMAPPING="
    -v $HOSTVOLROOT/etc/nginx/:/etc/nginx/:Z
    -v $HOSTVOLROOT/etc/pki/tls/:/etc/pki/tls:Z
    -v $HOSTVOLROOT/var/cache/nginx:/var/cache/nginx:Z
    -v $HOSTVOLROOT/var/log/nginx:/var/log/nginx:Z
    -v $HOSTVOLROOT/var/www:/var/www:Z
"

# first create user/group/host directories if not existing
if ! id -u $CONTAINERUSER &>/dev/null; then
    groupadd -g $CONTAINERUID $CONTAINERUSER
    adduser -M -g $CONTAINERUID -u $CONTAINERUID $CONTAINERUSER
fi
if [ -d $HOSTVOLROOT/var/log/$CONTAINERNAME ]; then
    mkdir -p $HOSTVOLROOT/var/log
    chown $CONTAINERUSER:$CONTAINERUSER $HOSTVOLROOT/var/log
fi
chkdir etc/nginx $CONTAINERUSER
chkdir etc/pki $CONTAINERUSER
chkdir var/cache/nginx $CONTAINERUSER
chkdir var/log/nginx $CONTAINERUSER
chkdir var/www $CONTAINERUSER
