# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
FROM ubuntu:bionic
MAINTAINER Moresby Media Development Team <dev@moresbymedia.com>

# Install stuff we needed.
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    curl \
    git \
    groff \
    mysql-client \
    php-pear \
    php \
    php-curl \
    php-mysqlnd \
    php-cli \
    php-xml \
    php-bcmath \
    php-simplexml \
    php-mbstring \
    php-intl \
    php-ssh2 \
    python-pip \
    ant \
    zip \
    wget \
    locales \
    software-properties-common \
    jq

#install nodejs and npm from the 12.x branch currently supported until Oct 2021
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install -y nodejs

RUN curl https://github.com/luke-chisholm6/go-cli-templates/releases/download/0.1.0/go-cli-templates_linux_amd64 -Lo /usr/local/bin/go-cli-templates && \
    chmod +x /usr/local/bin/go-cli-templates

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/local/bin \
    && php -r "unlink('composer-setup.php');"

RUN pip install --upgrade pip
RUN pip install awscli

RUN curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest \
    && chmod +x /usr/local/bin/ecs-cli

RUN pear channel-discover pear.phing.info && pear install -Z phing/phing
RUN curl -L "https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

RUN mkdir -p /usr/local/swagger && wget https://repo1.maven.org/maven2/io/swagger/swagger-codegen-cli/2.2.2/swagger-codegen-cli-2.2.2.jar -O /usr/local/swagger/swagger-codegen-cli.jar

#RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g swagger-cli webpack

# Add locales after locale-gen as needed
# Upgrade packages on image
# Preparations for sshd
RUN locale-gen en_US.UTF-8 &&\
    apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openssh-server &&\
    apt-get -q autoremove -y &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

# Install JDK 7 (latest edition)
RUN apt-get -q update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openjdk-11-jre-headless &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Set user jenkins to the image
RUN useradd -m -d /home/jenkins -s /bin/sh jenkins && echo "jenkins:jenkins" | chpasswd
RUN usermod -aG sudo jenkins
RUN echo 'root:root' | chpasswd
RUN sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Standard SSH port
EXPOSE 22

# Default command
CMD ["/usr/sbin/sshd", "-D"]
