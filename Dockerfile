FROM ubuntu:24.04 AS usage

ARG uid=1000
ARG gid=1000

# Install base environment.

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo passwd coreutils findutils bash git curl rsync \
    make gcc g++ musl-dev libc6-dev linux-headers-generic \
    pkg-config wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Remove default user and group with UID/GID 1000 if they exist.
RUN if getent passwd 1000 > /dev/null; then userdel -r -f $(getent passwd 1000 | cut -d: -f1); fi && \
    if getent group 1000 > /dev/null; then groupdel $(getent group 1000 | cut -d: -f1); fi


# Install some dependencies.

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libelf-dev libelf1 zlib1g-dev libzstd-dev && \
    rm -rf /var/lib/apt/lists/*

# Extra tools.

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    manpages manpages-posix bash-completion vim \
    iproute2 vlan bridge-utils net-tools \
    netcat-openbsd iputils-ping \
    wget lynx w3m \
    stress-ng jq && \
    rm -rf /var/lib/apt/lists/*


# Test a few domains.

RUN curl -qs https://www.example.com  -o /dev/null || true \
 && curl -qs https://xvideos.com      -o /dev/null || true \
 && curl -qs https://pastebin.com     -o /dev/null || true \
 && curl -qs https://www.uol.com.br   -o /dev/null || true \
 && curl -qs https://www.aol.com      -o /dev/null || true \
 && curl -qs https://transfer.sh      -o /dev/null || true \
 && curl -qs https://filebin.net      -o /dev/null || true \
 && curl -qs https://temp.sh          -o /dev/null || true \
 && curl -qs https://termbin.com      -o /dev/null || true \
 && curl -qs https://gofile.io        -o /dev/null || true

# Allow environment variables through sudo.

RUN echo "Defaults env_keep += \"LANG LC_* HOME EDITOR PAGER GIT_PAGER MAN_PAGER\"" > /etc/sudoers && \
    echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "rafaeldtinoco ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chmod 0440 /etc/sudoers

# Prepare rafaeldtinoco user to be $UID:$GID host equivalent.

RUN export uid=$uid gid=$gid && \
    mkdir -p /home/rafaeldtinoco && \
    echo "rafaeldtinoco:x:${gid}:" >> /etc/group && \
    echo "rafaeldtinoco:x:${uid}:${gid}:rafaeldtinoco,,,:/home/rafaeldtinoco:/bin/bash" >> /etc/passwd && \
    echo "rafaeldtinoco::99999:0:99999:7:::" >> /etc/shadow && \
    chown ${uid}:${gid} -R /home/rafaeldtinoco && \
    echo "export PS1=\"\u@\h[\w]$ \"" > /home/rafaeldtinoco/.bashrc && \
    echo "alias ls=\"ls --color\"" >> /home/rafaeldtinoco/.bashrc && \
    echo "set -o vi" >> /home/rafaeldtinoco/.bashrc && \
    ln -s /home/rafaeldtinoco/.bashrc /home/rafaeldtinoco/.profile

# hadolint ignore=DL3002
USER root
WORKDIR /home/rafaeldtinoco
ENV HOME=/home/rafaeldtinoco

RUN echo "#!/bin/bash" > /script.sh && \
    echo "echo 'Environment ready.'" >> /script.sh && \
    chmod +x /script.sh

ENTRYPOINT ["/script.sh"]


