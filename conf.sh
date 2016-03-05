#!/usr/bin/env bash

# configure container
export IMGID='2'  # range from 2 .. 99; must be unique
export IMAGENAME="r2h2/nginx${IMGID}"
export CONTAINERNAME="${IMGID}nginx"
export CONTAINERUSER="nginx${IMGID}"   # group and user to run container
export CONTAINERUID="800${IMGID}"   # gid and uid for CONTAINERUSER
export ENVSETTINGS=''
export NETWORKSETTINGS="
    -p 80:8080
    -p 443:8443
    --net http_proxy
    --net-alias mdfeed.test.wpv.portalverbund.at
    --ip 10.1.1.${IMGID}
"
export VOLROOT="/docker_volumes/$CONTAINERNAME"  # container volumes on docker host
export VOLMAPPING="
    -v $VOLROOT/etc/nginx/:/etc/nginx/:Z
    -v $VOLROOT/etc/pki/tls/:/etc/pki/tls:Z
    -v $VOLROOT/var/cache/nginx:/var/cache/nginx:Z
    -v $VOLROOT/var/log/nginx:/var/log/nginx:Z
    -v $VOLROOT/var/www:/var/www:Z
    -v /docker_volumes/3pyffTestWpv/var/md_feed/:/var/www/mdfeedTestWpvPortalverbundAt
"
export STARTCMD='/start.sh'

# first create user/group/host directories if not existing
if ! id -u $CONTAINERUSER &>/dev/null; then
    groupadd -g $CONTAINERUID $CONTAINERUSER
    adduser -M -g $CONTAINERUID -u $CONTAINERUID $CONTAINERUSER
fi
if [ -d $VOLROOT/var/log/$CONTAINERNAME ]; then
    mkdir -p $VOLROOT/var/log
    chown $CONTAINERUSER:$CONTAINERUSER $VOLROOT/var/log
fi
# create dir with given user if not existing, relative to $HOSTVOLROOT; set/repair ownership
function chkdir {
    dir=$1
    user=$2
    mkdir -p "$VOLROOT/$dir"
    chown -R $user:$user "$VOLROOT/$dir"
}
chkdir var/cache/nginx $CONTAINERUSER
chkdir var/log/nginx $CONTAINERUSER
chkdir var/www $CONTAINERUSER
