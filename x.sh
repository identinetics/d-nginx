#!/usr/bin/env bash

main() {
    SCRIPTDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
    source $SCRIPTDIR/dscripts/conf_lib.sh  $@         # load library functions
    configlib_version=2  # compatible version of conf_lib.sh
    check_version $configlib_version
    init_sudo
    _set_volume_root
    _set_image_and_container_name
    #_set_users
    #_set_buildargs
    #_set_run_args
    #_set_logfiles
}


_set_volume_root() {
    # container volumes mounted to host paths, or symlinks to docker volumes
    DOCKERVOL_SHORT='/dv'
    DOCKERLOG_SHORT='/dl'
    if [[ "$TRAVIS" == "true" ]] || [[ ! -z ${JENKINS_HOME+x} ]]; then
        DOCKERVOL_SHORT='./dv';
        DOCKERLOG_SHORT='./dl';
    fi
    mkdir -p $DOCKERVOL_SHORT $DOCKERLOG_SHORT
    DOCKER_VOLUME_ROOT='/var/lib/docker/volumes'  # hard coded - check for your config if applicable!
}


_set_image_and_container_name() {
    # imgid qualifies image, container, user and IP adddress; this is helpful for managing
    # processes on the docker host etc.
    imgid='02'  # range from 02 .. 99; must be unique per node
    projshort='nginx'
    export SERVICEDESCRIPTION=loadbalancer
    #export DOCKER_REGISTRY_USER='myuser'  # overwrite default user 'local'
    #export DOCKER_REGISTRY_HOST='localhost:5000'  # overwrite default registry host
    set_docker_registry
    export IMAGENAME="${DOCKER_REGISTRY_USER}/${projshort}"
    export CONTAINERNAME="${imgid}$projshort"
    export IMAGE_TAG_PRODENV='pr'  # required for standalone run script (-> `run.sh -w`)
}


_set_users() {
    export CONTAINERUSER="$projshort${imgid}"   # group and user to run container
    export CONTAINERUID="3430${imgid}"     # gid and uid for CONTAINERUSER
    export START_AS_ROOT=      # 'True'
}


_set_buildargs() {
    export BUILDARGS="
        --build-arg USERNAME=$CONTAINERUSER
        --build-arg UID=$CONTAINERUID
    "
    unset REPO_STATUS  # if set: generate 'REPO_STATUS' file to be included in docker image
    export MANIFEST_SCOPE='local'  # valid values: 'global', 'local'. Extension for manifest library.
                                   # must be local for targets. Requires write access to git for 'global'.
}


_set_run_args() {
    LOGPURGEFILES='/var/log/httpd/* /var/log/shibboleth/*'
    export ENVSETTINGS="
        -e LOGDIR=/var/log
        -e LOGPURGEFILES
        -e LOGLEVEL=INFO
    "
    get_capabilities
    export STARTCMD='/start.sh'  # unset or blank to use image default
}


create_intercontainer_network() {
    # Create a local network on the docker host. As the default docker0 bridge has dynamic
    # addresses, a custom bridge is created allowing predictable addresses.
    network='dockernet'
    set +e  # errexit off
    $sudo docker network ls | awk '{print $2}' | grep $network > /dev/null
    if (( $? == 1)); then
        $sudo docker network create --driver bridge --subnet=10.1.1.0/24 \
                  -o com.docker.network.bridge.name=br-$network $network
    fi
    export NETWORKSETTINGS="
        --net $network
        --net-alias www.test.wpv.portalverbund.at
        --ip 10.1.1.${imgid}
        -p 80:8080
        -p 443:8443
    "
}


setup_vol_mapping() {
    # Create docker volume (-> map_docker_volume) or map a host dir (-> map_host_directory)
    # In both cases create a shortcut in the shortcut directory (DOCKERVOL_SHORT, DOCKERLOG_SHORT)
    mode=$1  # create (used by run.sh)/list (used by manage.sh)
    export VOLLIST=''
    export VOLMAPPING=''
    # create container user on docker host (optional - for better process visibility with host tools)
    create_user $CONTAINERUSER $CONTAINERUID

    map_docker_volume $mode "${CONTAINERNAME}.etc_letsencrypt" '/etc/letsencrypt' 'Z' $DOCKERVOL_SHORT
    map_docker_volume $mode "${CONTAINERNAME}.etc_nginx" '/etc/nginx' 'ro' $DOCKERVOL_SHORT
    map_docker_volume $mode "${CONTAINERNAME}.etc_pki_tls" '/etc/pki/tls' 'ro' $DOCKERVOL_SHORT
    map_docker_volume $mode "${CONTAINERNAME}.var_lib" '/var/lib' 'Z' $DOCKERVOL_SHORT
    map_docker_volume $mode "${CONTAINERNAME}.var_log" '/var/log' 'Z' $DOCKERLOG_SHORT
    map_docker_volume $mode "${CONTAINERNAME}.var_www" '/var/www' 'Z' $DOCKERVOL_SHORT
    if [[ ! $JENKINS_HOME ]]; then
        chown -R $CONTAINERUSER:$CONTAINERUSER $DOCKER_VOLUME_ROOT/${CONTAINERNAME}.*
    fi
}


_set_logfiles () {
    export KNOWN_LOGFILES="
        ${DOCKERLOG_SHORT}/${CONTAINERNAME}.var_log/nginx/access.log
        ${DOCKERLOG_SHORT}/${CONTAINERNAME}.var_log/nginx/main_error.log
    "
}


container_status() {
    $sudo docker ps | head -1
    $sudo docker ps --all | egrep $CONTAINERNAME\$
    $sudo docker exec -it $CONTAINERNAME /status.sh
}


logrotate() {
    find $DOCKERLOG_SHORT/${CONTAINERNAME}.var_log/ -mtime +5 -exec ls -ld {} \;
}


main $@
