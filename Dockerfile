ARG DOTNETVERSION=3.1
FROM mcr.microsoft.com/dotnet${DOTNETEXTRAFOLDER}/aspnet:${DOTNETVERSION}-alpine

# Environment variables
ENV \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    TERM="xterm-256color"

# Copy root filesystem
COPY rootfs /

# Set shell
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Install base system
ARG TARGETPLATFORM=amd64
RUN \
    set -o pipefail \
    \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    \
    && apk add --no-cache --virtual .build-dependencies \
        tar=1.34-r0 \
    \
    && apk add --no-cache \
        libcrypto1.1=1.1.1k-r0 \
        libssl1.1=1.1.1k-r0 \
        musl-utils=1.2.2-r0 \
        musl=1.2.2-r0 \
    \
    && apk add --no-cache \
        shadow=4.8.1-r0 \
        bash=5.1.0-r0 \
        curl=7.77.0-r1 \
        jq=1.6-r1 \
        tzdata=2021a-r0 \
    \
    && S6_ARCH="${TARGETPLATFORM}" \
    && if [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then S6_ARCH="armhf"; fi \
    && if [ "${TARGETPLATFORM}" = "arm64" ]; then S6_ARCH="aarch64"; fi \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-${S6_ARCH}.tar.gz" \
        | tar zxvf - -C / \
    \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.8.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
    && apk del --no-cache --purge .build-dependencies \
    && rm -f -r \
        /tmp/* \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc \
    && mkdir -p /app

WORKDIR /app

# Entrypoint & CMD
ENTRYPOINT ["/init"]

