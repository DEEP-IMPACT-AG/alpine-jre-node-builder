FROM deepimpact/alpine-jre-node:1.0.2

ENV GIT_LFS_VERSION 2.4.2

# Install base packages
RUN apk update && \
    apk add curl docker git openjdk8="$JAVA_ALPINE_VERSION" python2 py2-pip sudo

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

