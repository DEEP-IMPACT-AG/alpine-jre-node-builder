FROM deepimpact/alpine-jre-node:1.0.2

# Taken directly from `https://github.com/frol/docker-alpine-glibc`
# Alpine is based on musl, and this enables some software packages 
# (such as flapdoodle) to run against glibc
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.28-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

ENV GIT_LFS_VERSION 2.4.2

# Install base packages
RUN apk update && \
    apk add curl docker git libelf openssh python2 py2-pip sudo make g++

# Enable wheel group entry
RUN sed -e 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' -i /etc/sudoers

# Add user `bmo`
RUN adduser -D bmo && \
    echo "bmo:bmo" | chpasswd && \
    sed -e 's/^wheel:\(.*\)/wheel:\1,bmo/g' -i /etc/group

# Install git lfs -TEMPORARY-
# add `git-lfs` among the package names above as soon as the base switches to alpine >3.7
RUN apk add openssl --update-cache && \
    wget -qO- https://github.com/git-lfs/git-lfs/releases/download/v"$GIT_LFS_VERSION"/git-lfs-linux-amd64-"$GIT_LFS_VERSION".tar.gz | tar xz && \
    mv git-lfs-*/git-lfs /usr/bin/ && \
    rm -rf git-lfs-* && \
    git lfs install 

# awscli
RUN pip install --upgrade pip && \
    pip install awscli

# Install Leiningen
RUN curl --silent https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > /usr/local/bin/lein && \
    chmod +x /usr/local/bin/lein && \
    su bmo -c "lein"

# Cleanup
RUN rm -rf /tmp/*

# Start as a non-root user
USER bmo

