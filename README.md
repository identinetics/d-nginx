# NGINX docker image using static network addresses for stable reverse proxy config 

A NGINX configuration to proxy multiple http services in other containers on the same docker host.
Specific features of this project:
1. NGINX runs as non-root user
2. The user-defined network uses static IP addresses. Therefore NGINX will not fail on startup 
   or reload if a container is not available. (Somebody else has to check! -> Monitoring tools)
3. Image is based on centos7     

The image produces immutable containers, i.e. a container can be removed and re-created
any time without loss of data, because data is stored on mounted volumes.

## Configuration

1. Clone this repository
2. Copy conf.sh.default to confXX.sh, where XX is a unique container number on the docker host
3. Run `git submodule init` and `git submodule update`
4. Modify confXX.sh

## Usage

    dscript/build.sh
    dscript/run.sh [-p] # start nginx in daemon mode
    dscript/run.sh -ir  # start interactive bash as root user  
    dscript/exec.sh -i  # open a second shell
