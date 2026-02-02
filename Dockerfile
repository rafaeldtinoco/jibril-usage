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

# Install clang.

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    clang-18 clangd-18 clang-format-18 clang-tools-18 lld-18 llvm-18 llvm-18-tools && \
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang-18 100 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-18 100 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-18 100 && \
    update-alternatives --install /usr/bin/llc llc /usr/lib/llvm-18/bin/llc 100 && \
    update-alternatives --install /usr/bin/llvm-strip llvm-strip /usr/lib/llvm-18/bin/llvm-strip 100 && \
    update-alternatives --install /usr/bin/llvm-config llvm-config /usr/lib/llvm-18/bin/llvm-config 100 && \
    update-alternatives --install /usr/bin/ld.lld ld.lld /usr/bin/ld.lld-18 100 && \
    update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/lib/llvm-18/bin/llvm-ar 100 && \
    update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/lib/llvm-18/bin/llvm-nm 100 && \
    update-alternatives --install /usr/bin/llvm-objcopy llvm-objcopy /usr/lib/llvm-18/bin/llvm-objcopy 100 && \
    update-alternatives --install /usr/bin/llvm-objdump llvm-objdump /usr/lib/llvm-18/bin/llvm-objdump 100 && \
    update-alternatives --install /usr/bin/llvm-readelf llvm-readelf /usr/lib/llvm-18/bin/llvm-readelf 100 && \
    update-alternatives --install /usr/bin/opt opt /usr/lib/llvm-18/bin/opt 100 && \
    rm -rf /var/lib/apt/lists/*

# Install golang.

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    golang && \
    mv /usr/lib/go /usr/lib/go.orig && \
    ARCH=$(uname -m) && \
    GO_ARCH="amd64" && \
    if [ "$ARCH" = "aarch64" ]; then GO_ARCH="arm64"; fi && \
    wget -q https://go.dev/dl/go1.24.0.linux-${GO_ARCH}.tar.gz && \
    tar -C /usr/lib/ -xzf ./go1.24.0.linux-${GO_ARCH}.tar.gz && \
    rm ./go1.24.0.linux-${GO_ARCH}.tar.gz && \
    /usr/lib/go/bin/go version && \
    rm -rf /var/lib/apt/lists/*

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

# Install linters.

RUN GOROOT=/usr/lib/go GOPATH="$HOME/go" \
    /usr/lib/go/bin/go install honnef.co/go/tools/cmd/staticcheck@latest && \
    /usr/lib/go/bin/go install github.com/mgechev/revive@latest && \
    cp "$HOME/go/bin/staticcheck" /usr/bin/ && \
    cp "$HOME/go/bin/revive" /usr/bin/

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


