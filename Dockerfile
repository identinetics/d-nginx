FROM centos:centos7
MAINTAINER Rainer Hörbe <r2h2@hoerbe.at>
# derived from https://github.com/nginxinc/docker-nginx/blob/master/stable/centos7/Dockerfile

ENV NGINX_VERSION 1.8.1-1.el7.ngx
COPY ./nginx.repo /etc/yum.repos.d/nginx.repo

RUN rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 \
 && yum -y install curl iproute lsof net-tools \
 && rpm --import http://nginx.org/keys/nginx_signing.key \
 && yum -y install ca-certificates nginx-${NGINX_VERSION} gettext \
 && yum clean all \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# Application will run as a non-root user/group that must map to the docker host
ARG USERNAME
ARG UID
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME \
 && chown $USERNAME:$USERNAME /run

COPY start.sh /
RUN chmod +x /start.sh
CMD /start.sh