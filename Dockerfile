FROM intra/centos7_py36_base
LABEL maintainer="Rainer Hörbe <r2h2@hoerbe.at>"

# General admin tools
RUN yum -y update \
 && yum -y install bind-utils curl iproute lsof mlocate net-tools openssl strace telnet unzip wget which \
 && yum -y install epel-release \
 && yum clean all

# Application will run as a non-root uid/gid that must map to the docker host
ARG USERNAME=nginx
ARG UID=343002
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME

#install RPM into CENTOS default paths (does not include naxsi as of 1.8.1)
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
ENV NGINX_VERSION nginx-1.17.1
ENV NAXSI_VERSION 0.56
RUN yum install -y gcc httpd-devel openssl-devel pcre perl pcre-devel zlib zlib-devel \
 && yum clean all
WORKDIR /usr/local/src
RUN wget http://nginx.org/download/$NGINX_VERSION.tar.gz \
 && tar -xpzf $NGINX_VERSION.tar.gz \
 && rm $NGINX_VERSION.tar.gz \
 && wget https://github.com/nbs-system/naxsi/archive/$NAXSI_VERSION.tar.gz \
 && tar -xvzf $NAXSI_VERSION.tar.gz \
 && rm $NAXSI_VERSION.tar.gz
WORKDIR /usr/local/src/$NGINX_VERSION/

RUN ./configure --prefix=/usr/local/nginx \
                --http-log-path=/var/log/nginx/access.log \
                --error-log-path=/var/log/nginx/error.log \
                --http-client-body-temp-path=/var/lib/nginx/body \
                --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
                --http-proxy-temp-path=/var/lib/nginx/proxy \
                --lock-path=/var/log/nginx.lock \
                --pid-path=/opt/var/log/nginx.pid \
                --add-module=/usr/local/src/naxsi-$NAXSI_VERSION/naxsi_src/ \
                --with-debug \
                --with-http_ssl_module --with-http_realip_module \
                --without-mail_pop3_module --without-mail_smtp_module \
                --without-mail_imap_module --without-http_uwsgi_module \
                --without-http_scgi_module --with-ipv6 \
                --with-http_gunzip_module --with-http_gzip_static_module \
                --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'
RUN make && make install && make clean

COPY install/opt /opt
RUN mkdir -p /var/log/nginx/ /var/lib/nginx/ /opt/var/log/ \
 && chown -R $USERNAME:$USERNAME /var/log/nginx/ /var/lib/nginx/ /opt/nginx_test/ /opt/var/log/
COPY install/scripts/*.sh /
RUN chmod +x /*.sh
CMD /start.sh

# === Let's Encrypt ===
RUN yum -y install certbot \
 && yum clean all \
 # fix yum cleanup problem
 && rm -rf /var/cache/yum/ /var/lib/rpm/__db* /var/log/lastlog /var/log/yum.log
RUN mkdir -p /etc/letsencrypt /var/log/letsencrypt/ /var/lib/letsencrypt /var/www/letsencrypt/ \
 && chown -R $USERNAME:$USERNAME /etc/letsencrypt /var/log/letsencrypt/ /var/lib/letsencrypt /var/www/letsencrypt/

# Note: use /etc/pki/tls for manually obtained certs; letsencrypt uses /etc/letsencrypt/live

VOLUME /etc/nginx \
       /etc/letsencrypt \
       /var/log \
       /var/www

# copy static content into /var/www

# require py3 for manifest generation
RUN mkdir -p $HOME/.config/pip \
 && printf "[global]\ndisable-pip-version-check = True\n" > $HOME/.config/pip/pip.conf
COPY install/opt/bin/manifest2.sh /opt/bin/manifest2.sh

EXPOSE 8080 8443
USER $USERNAME