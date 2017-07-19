# NGINX docker image with naxsi support and static network addresses for stable reverse proxy config 

A NGINX configuration to proxy multiple http services in other containers on the same docker host.
Specific features of this project:

1. NGINX runs as non-root user
2. The user-defined network uses static IP addresses. Therefore NGINX will not fail on startup 
   or reload if a container is not available. (Somebody else has to check! -> Monitoring tools)
3. Image is based on centos7
4. Obtain certificates from Let's Encrypt

The image produces immutable containers, i.e. a container can be removed and re-created
any time without loss of data, because data is stored on mounted volumes.

## Configuration

1. Clone this repository
2. Copy or symlink conf.sh.default to conf.sh
3. Run `git submodule update --init && cd dscripts && git checkout master && cd -`
4. Optionally modify conf.sh
5. Configure /etc/nginx (see also example install/nginx.conf for TLS and logformat settings)
6. Configure naxsi rules accoring to https://github.com/nbs-system/naxsi/wi

## Usage

    dscript/build.sh
    dscript/run.sh [-p] # start nginx in daemon mode
    dscript/run.sh -ir  # start interactive bash as root user  
    dscript/run.sh -i /start_test.sh  # run test configuration with sample naxsi rules  
    dscript/exec.sh -i  # open a second shell

## Letsencrypt Certs

### Add certificate

Configure vhost in server.d with HTTP only and make sure it will run. 
Insert into nginx server config:

    location /.well-known {   # letsencrypt certbot  
      root /var/www/letsencrypt/wwwExampleOrg;
      allow all;
    }
    
Then run:

    fqdn=www.example.com
    mkdir -p /var/www/letsencrypt/$fqdn/.well-known
    certbot certonly -a webroot --webroot-path=/var/www/letsencrypt/$fqdn/ -d $fqdn

Enable https and restart Nginx

    
### Renew
    
    certbot renew