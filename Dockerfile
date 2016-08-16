FROM centos:centos7
MAINTAINER Rainer Hörbe <r2h2@hoerbe.at>
# derived from https://github.com/nginxinc/docker-nginx/blob/master/stable/centos7/Dockerfile

#install RPM into CENTOS default paths
#ENV NGINX_VERSION 1.8.1-1.el7.ngx
#COPY install/nginx.repo /etc/yum.repos.d/nginx.repo
#RUN rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 \
# && yum -y install bind-utils curl iproute lsof mlocate net-tools telnet unzip which
# && rpm --import http://nginx.org/keys/nginx_signing.key \
# && yum -y install ca-certificates nginx-${NGINX_VERSION} gettext \
# && yum clean all \
# && ln -sf /dev/stdout /var/log/nginx/access.log \
# && ln -sf /dev/stderr /var/log/nginx/error.log

# Compile and install NGINX with NAXSI enabled using /opt/nginx
ENV NGINX_VERSION nginx-1.8.1
ENV NAXSI_VERSION 0.54
RUN yum -y install bind-utils curl iproute lsof mlocate net-tools telnet unzip wget which \
 && yum install -y gcc httpd-devel pcre perl pcre-devel zlib zlib-devel
WORKDIR /usr/local/src
RUN wget http://nginx.org/download/$NGINX_VERSION.tar.gz \
 && tar -xpzf $NGINX_VERSION.tar.gz \
 && rm $NGINX_VERSION.tar.gz \
 && wget https://github.com/nbs-system/naxsi/archive/$NAXSI_VERSION.tar.gz \
 && tar -xvzf $NAXSI_VERSION.tar.gz
WORKDIR /usr/local/src/$NGINX_VERSION/

RUN ./configure --conf-path=/opt/etc/nginx.conf \
                --add-module=/usr/local/$NAXSI_VERSION/naxsi_src/ \
                --error-log-path=/var/log/nginx/error.log \
                --http-client-body-temp-path=/usr/local/nginx/body \
                --http-fastcgi-temp-path=/usr/local/nginx/fastcgi \
                --http-log-path=/var/log/nginx/access.log \
                --http-proxy-temp-path=/usr/local/nginx/proxy \
                --lock-path=/var/lock/nginx.lock \
                --pid-path=/var/run/nginx.pid \
                --with-http_ssl_module --with-http_realip_module \
                --without-mail_pop3_module --without-mail_smtp_module \
                --without-mail_imap_module --without-http_uwsgi_module \
                --without-http_scgi_module --with-ipv6 --prefix=/usr/local/nginx \
                --with-http_gunzip_module --with-http_gzip_static_module \
                --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'


RUN make && make install


# Application will run as a non-root user/group that must map to the docker host
ARG USERNAME=nginx
ARG UID=1001
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME \
 && chown $USERNAME:$USERNAME /var/run

COPY install/scripts/*.sh /
RUN chmod +x /*.sh
CMD /start.sh