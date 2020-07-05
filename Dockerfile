ARG BASE=ubuntu:20.04
FROM ${BASE}

LABEL maintainer="https://github.com/dmrub"

ENV OPENSSH_PORT=22 \
    OPENSSH_ROOT_PASSWORD="" \
    OPENSSH_ROOT_AUTHORIZED_KEYS="" \
    OPENSSH_USER="ssh" \
    OPENSSH_USERID=1001 \
    OPENSSH_GROUP="ssh" \
    OPENSSH_GROUPID=1001 \
    OPENSSH_PASSWORD="" \
    OPENSSH_AUTHORIZED_KEYS="" \
    OPENSSH_HOME="/home/ssh" \
    OPENSSH_SHELL="/bin/bash" \
    OPENSSH_RUN="" \
    OPENSSH_ALLOW_TCP_FORWARDING="all"

RUN set -ex; \
    if ! command -v gpg > /dev/null; then \
        export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            gnupg \
            dirmngr \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      openssh-server rsync augeas-tools; \
    chmod +x /usr/local/bin/entrypoint.sh; \
    rm -f /etc/motd; \
    passwd -d root; \
    mkdir -p ~root/.ssh /etc/authorized_keys; \
    printf 'set /files/etc/ssh/sshd_config/AuthorizedKeysFile ".ssh/authorized_keys /etc/authorized_keys/%%u"\n'\
'set /files/etc/ssh/sshd_config/ClientAliveInterval 30\n'\
'set /files/etc/ssh/sshd_config/ClientAliveCountMax 5\n'\
'set /files/etc/ssh/sshd_config/PermitRootLogin yes\n'\
'set /files/etc/ssh/sshd_config/PasswordAuthentication yes\n'\
'set /files/etc/ssh/sshd_config/Port 22\n'\
'set /files/etc/ssh/sshd_config/AllowTcpForwarding no\n'\
'set /files/etc/ssh/sshd_config/Match[1]/Condition/Group "wheel"\n'\
'set /files/etc/ssh/sshd_config/Match[1]/Settings/AllowTcpForwarding yes\n'\
'save\n'\
'quit\n' | augtool; \
    cp -a /etc/ssh /etc/ssh.cache; \
    apt-get remove -y augeas-tools; \
    rm -rf /var/lib/apt/lists/*

# grab tini for signal processing and zombie killing
ENV TINI_VERSION v0.19.0
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -y; \
    apt-get install -y --no-install-recommends wget ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini"; \
    wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    for server in $(shuf -e hkps://keys.openpgp.org \
                                hkp://p80.pool.sks-keyservers.net:80 \
                                keyserver.ubuntu.com \
                                hkp://keyserver.ubuntu.com:80) ; do \
        gpg --no-tty --keyserver "$server" --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 && break || : ; \
    done; \
    gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
    { command -v gpgconf > /dev/null && gpgconf --kill all || :; }; \
    rm -rf "$GNUPGHOME" /usr/local/bin/tini.asc; \
    chmod +x /usr/local/bin/tini; \
    tini -h

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
