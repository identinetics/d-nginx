FROM nginx
MAINTAINER Rainer Hörbe <r2h2@hoerbe.at>

#RUN yum -y install epel-release curl net-tools unzip

# Application will run as a non-root user/group that must map to the docker host
ARG USERNAME
ARG UID
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME \
 && chown nginx1:nginx1 /run

COPY start.sh /
RUN chmod +x /start.sh
CMD /start.sh