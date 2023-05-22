#!/bin/bash


# Set FROM `image name`
set_image() {
  echo -e "FROM $1" >> $file_name
}

# Set ENV DEBIAN_FRONTEND=`env`
set_debian_frontend() {
  echo -e "
#=================
# DEBIAN_FRONTEND
#=================" >> $file_name
  echo -e "ENV DEBIAN_FRONTEND=$1" >> $file_name
}

# Set USER `username`
set_user() {
  echo -e "
#==========
# Set USER 
#==========" >> $file_name
  echo -e "USER $1" >> $file_name
}

# Set WORKDIR `path to workdir`
set_workdir() {
  echo -e "
#=============
# Set WORKDIR
#=============" >> $file_name
  echo -e "WORKDIR $1" >> $file_name
}

# Set RUN `general packages`
set_general_packages() {
  echo -e "
#==================
# General Packages
#==================" >> $file_name
  echo -e "RUN $1" >> $file_name
}

# Add adb package 
add_adb_package() {
  echo -e "
#==============
# ADB package
#==============" >> $file_name
  echo -e "RUN apk add \\
    android-tools \\
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> $file_name
}

# Add kubectl package 
add_kubectl_packages() {
  echo -e "
#==============
# kubectl package
#==============" >> $file_name
  echo -e "RUN curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\" && \\
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \\
    kubectl version --client" >> $file_name
}

# Add MkDocs packages
add_mkdocs_packages() {
  echo -e "
#==============
# MkDocs packages
#==============" >> $file_name
  echo -e "RUN apk add --no-cache --update py-pip \\
    python3 \\
    gcc \\
    python3-dev \\
    musl-dev && \\
    pip install mkdocs mkdocs-material" >> $file_name
}

# Install docker package 
add_docker_package() {
  echo -e "
#==============
# Docker package
#==============" >> $file_name
  echo -e "RUN apk add --no-cache docker openrc \\
    && rc-update add docker boot" >> $file_name
}

# Add ENV JAVA_HOME and ENV PATH
add_java_home() {
  echo -e "
#==============
# Set JAVA_HOME 
#==============" >> $file_name
  echo -e "ENV JAVA_HOME=\"/usr/lib/jvm/java-17-openjdk\"
ENV PATH=\$PATH:\$JAVA_HOME/bin" >> $file_name
}

# Add Jenkins Swarm
add_jenkins_swarm() {
  echo -e "
#==============
# Add Jenkins Swarm
#==============" >> $file_name
  echo -e "ENV JENKINS_SLAVE_ROOT=\"/opt/jenkins\"

USER root

RUN mkdir -p \"\$JENKINS_SLAVE_ROOT\"
RUN mkdir -p /opt/apk

# Slave settings
ENV JENKINS_MASTER_USERNAME=\"jenkins\" \\
    JENKINS_MASTER_PASSWORD=\"jenkins\" \\
    JENKINS_MASTER_URL=\"http://jenkins:8080/\" \\
    JENKINS_SLAVE_MODE=\"exclusive\" \\
    JENKINS_SLAVE_NAME=\"swarm-\$RANDOM\" \\
    JENKINS_SLAVE_WORKERS=\"1\" \\
    JENKINS_SLAVE_LABELS=\"\" \\
    AVD=\"\"" >> $file_name
}

# Add LANG, LANGUAGE and LC_ALL
add_language_env() {
  echo -e "
#==============
# Set language
# you can also specify it as as environment variable through docker-compose.yml 
#==============" >> $file_name
  echo -e "ENV LANG=en_US.UTF-8 \\
    LANGUAGE=en_US.UTF-8\\
    LC_ALL=en_US.UTF-8" >> $file_name
}

# Set entrypoint
set_entrypoint() {
  echo -e "
#==============
# Add entrypoint
#==============" >> $file_name
echo -e "$1" >> $file_name
}


# Build Dockerfile
docker() {
  set_image "alpine:edge"
  set_debian_frontend "noninteractive"
  set_workdir "/root"
  set_general_packages "apk add --no-cache \\
    bash \\
    openjdk17 \\
    tzdata \\
    curl \\
    git \\
    git-fast-import \\
    openssh-client \\
    bind-tools \\
    gnupg \\
    lsof && \\
    rm -rf /var/lib/apt/lists/* /usr/lib/jvm/java-17-openjdk/demo /usr/lib/jvm/java-17-openjdk/man /usr/lib/jvm/java-17-openjdk/jre/demo /usr/lib/jvm/java-17-openjdk/jre/man"
  add_adb_package
  add_kubectl_packages
  add_java_home
  add_jenkins_swarm
  add_language_env
  set_entrypoint "ADD entrypoint.sh /

ENTRYPOINT [\"/entrypoint.sh\"]"
}

# Build Dockerfile-docker
docker1() {
  set_image "alpine:3.16.2"
  set_debian_frontend "noninteractive"
  set_workdir "/root"
  set_general_packages "apk add --no-cache \\
    bash \\
    openjdk17 \\
    tzdata \\
    curl \\
    git \\
    git-fast-import \\
    openssh-client \\
    bind-tools \\
    gnupg \\
    lsof && \\
    rm -rf /var/lib/apt/lists/* /usr/lib/jvm/java-17-openjdk/demo /usr/lib/jvm/java-17-openjdk/man /usr/lib/jvm/java-17-openjdk/jre/demo /usr/lib/jvm/java-17-openjdk/jre/man"
  add_mkdocs_packages
  add_kubectl_packages
  add_docker_package
  add_java_home
  add_jenkins_swarm
  add_language_env
  set_entrypoint "ADD entrypoint.sh /

ENTRYPOINT [\"/entrypoint.sh\"]"
}


# Build Dockerfile-jnpl
jnpl() {
  set_image "jenkins/inbound-agent:latest-jdk17"
  set_debian_frontend "noninteractive"
  set_user "root"
  set_workdir "/root"
  set_general_packages "apt-get -qqy update && \\
	apt-get -qqy --no-install-recommends install lsof android-tools-adb"
  set_user "\${user}"
  set_workdir "/home/\${user}"
  set_entrypoint "ENTRYPOINT [\"jenkins-agent\"]"
}

# Build Dockerfile-python
python() {
  set_image "python:3.7.12-slim"
  set_debian_frontend "noninteractive"
  set_workdir "/root"
  set_general_packages "apt-get update && \\
    apt-get install -y -q \\
    bash \\
    openjdk-17-jdk \\
    tzdata \\
    curl \\
    git \\
    openssh-client && \\
    rm -rf /var/lib/apt/lists/* /usr/lib/jvm/java-17-openjdk/demo /usr/lib/jvm/java-17-openjdk/man /usr/lib/jvm/java-17-openjdk/jre/demo /usr/lib/jvm/java-17-openjdk/jre/man"
  add_java_home
  add_jenkins_swarm
  add_language_env
  set_entrypoint "ADD entrypoint.sh /

ENTRYPOINT [\"/entrypoint.sh\"]"
}

# Help
echo_help() {
  echo "
    Usage: ./build.sh [option]
    Flags:
        --help | -h    Print help
    Arguments:
        docker          Create DOCKER dockerfile
        docker1         Create DOCKER1 dockerfile
        jnpl            Create JNPL dockerfile
        python          Create Python dockerfile
        "
    exit 0
}

# Name of Dockerfile
file_name="Dockerfile-1"
# Clear file
true > $file_name

case $1 in
  docker)
    docker
    ;;
  docker1)
    docker1
    ;;
  jnpl)
    jnpl
    ;;
  python)
    python
    ;;
  *)
    echo "Invalid option detected: $1"
    echo_help
    ;;
esac
