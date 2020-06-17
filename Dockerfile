FROM rclone/rclone

ARG BRANCH="master"
ARG BRANCH="master"
ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"
ARG VCS_REF="unknown"
ARG VCS_URL="unknown"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}

# linking the base image's rclone binary to the path expected by cloudplow's default config
RUN ln /usr/local/bin/rclone /usr/bin/rclone

# configure environment variables to keep the start script clean
ENV CLOUDPLOW_CONFIG=/config/config.json
ENV CLOUDPLOW_LOGFILE=/config/cloudplow.log
ENV CLOUDPLOW_LOGLEVEL=DEBUG
ENV CLOUDPLOW_CACHEFILE=/config/cache.db
ENV LOCAL_LOCATION=/cloudplow/local
ENV CLOUD_LOCATION=/cloudplow/cloud
ENV UNION_LOCATION=/cloudplow/union
ENV LANDING_LOCATION=/cloudplow/landing
ENV MEDIA_SUBFOLDER=/media
ENV RCLONE_REMOTE_MOUNT="google_crypt:"
ENV RCLONE_LANDING_MOUNT="gcrypt:"
ENV RCLONE_LOGFILE=/config/cloudplow.log
ENV RCLONE_MOUNT_OPTIONS="--allow-other --buffer-size 256M --dir-cache-time 1000h --log-level INFO --log-file /config/rclone.log --poll-interval 15s --timeout 1h --read-only"
ENV MERGERFS_OPTIONS="-o rw,async_read=false,use_ino,allow_other,func.getattr=newest,category.action=all,category.create=ff,cache.files=partial,dropcacheonclose=true"

# map /config to host directory containing cloudplow config (used to store configuration from app)
VOLUME /config

# map /rclone_config to host directory containing rclone configuration files
VOLUME /rclone_config

# map /service_accounts to host directory containing Google Drive service account .json files
VOLUME /service_accounts

# map /data to media queued for upload
VOLUME /data

# change alpine repository to edge branch 
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# install dependencies for cloudplow, and user management, upgrade pip
RUN apk update --no-cache && \
    apk -U add --no-cache \
    ca-certificates \
    coreutils \
    findutils \
    git \
    grep \
    mergerfs \
    py3-pip \
    python3 \
    shadow \
    tzdata && \
    python3 -m pip install --no-cache-dir --upgrade pip

# install s6-overlay for process management
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# download cloudplow
RUN git clone --depth 1 --single-branch --branch ${BRANCH} https://github.com/l3uddz/cloudplow /opt/cloudplow

# download crop
RUN git clone --depth 1 --single-branch --branch ${BRANCH} https://github.com/watchmeexplode5/crop-lclone-docker/crop /usr/bin/
RUN chmod +x /usr/bin/crop

# download crop
RUN git clone --depth 1 --single-branch --branch ${BRANCH} https://github.com/watchmeexplode5/crop-lclone-docker/lclone /usr/bin/
RUN chmod +x /usr/bin/lclone

WORKDIR /opt/cloudplow
ENV PATH=/opt/cloudplow:${PATH}

# install pip requirements
RUN python3 -m pip install --no-cache-dir --upgrade -r requirements.txt

# install mergerfs
#RUN mergerfs -y

# remove fuse allow-others comment
RUN sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# add s6-overlay scripts and config
ADD root/ /

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/init"]