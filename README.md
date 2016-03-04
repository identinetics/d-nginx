# NGINX docker image with static network addresses for stable reverse proxy config 

A NGINX configuration to proxy multiple http services in other containers on the same docker host.
Specific features of this project:
1. NGINX runs as non-root user
2. The user-defined network uses static IP addresses. Therefore NGINX will not fail on startup 
   or reload if a container is not available. (Somebody else has to check! -> Monitoring tools)
3. Image is based on centos7     

The image produces immutable containers, i.e. a container can be removed and re-created
any time without loss of data, because data is stored on mounted volumes.

# Build the docker image
1. adapt conf.sh
2. run build.sh: 


## Usage: 
    run.sh -h  # print usage
    run.sh     # daemon mode
    run.sh -ipr bash  # interavtive, print run command, root user 
    