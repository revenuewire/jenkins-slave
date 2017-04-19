# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
FROM ubuntu:xenial
MAINTAINER Scott Wang <swang@revenuewire.com>

# Install stuff we needed.
RUN apt-get update && apt-get install -y \
    curl \
    git \
    groff \
    mysql-client \
    nodejs \
    npm \
    php-pear \
    php \
    php-curl \
    php-mysqlnd \
    python-pip \
    ant \
    zip \
    wget \
    locales

RUN pip install awscli
RUN pear channel-discover pear.phing.info && pear install -Z phing/phing
RUN curl -L "https://github.com/docker/compose/releases/download/1.8.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
# install kubernetes control cli tool
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

RUN mkdir -p /usr/local/swagger && wget http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/2.2.2/swagger-codegen-cli-2.2.2.jar -O /usr/local/swagger/swagger-codegen-cli.jar

RUN ln -s /usr/bin/nodejs /usr/bin/node
# Add locales after locale-gen as needed
# Upgrade packages on image
# Preparations for sshd
RUN locale-gen en_US.UTF-8 &&\
    apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openssh-server &&\
    apt-get -q autoremove &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

RUN wget https://releases.rancher.com/compose/v0.8.6/rancher-compose-linux-amd64-v0.8.6.tar.gz -O /tmp/rancher-compose-linux-amd64-v0.8.6.tar.gz \
        && tar xzvf /tmp/rancher-compose-linux-amd64-v0.8.6.tar.gz \
        && cp rancher-compose-v0.8.6/rancher-compose /usr/local/bin/rancher-compose \
        && rm -rf rancher-compose-v0.8.6

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

# Install JDK 7 (latest edition)
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openjdk-9-jre-headless &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Set user jenkins to the image
RUN useradd -m -d /home/jenkins -s /bin/sh jenkins && echo "jenkins:jenkins" | chpasswd
RUN usermod -aG sudo jenkins
RUN echo 'root:root' | chpasswd
RUN sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Standard SSH port
EXPOSE 22

# Default command
CMD ["/usr/sbin/sshd", "-D"]