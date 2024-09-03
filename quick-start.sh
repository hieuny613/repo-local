#!/bin/bash

# Đường dẫn log
LOG_FILE="/var/log/repo/repo_local.log"

# Hàm ghi log
log() {
    echo "$(date +'%d-%m-%YT%H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Kiểm tra quyền root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "Script must be run as root. Exiting."
        exit 1
    fi
}

# Cài đặt Docker trên Ubuntu
install_docker_ubuntu() {
    log "Updating package database..."
    apt-get update -y

    log "Installing prerequisite packages..."
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    log "Adding Docker's official GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    log "Adding Docker repository..."
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    log "Updating package database..."
    apt-get update -y

    log "Installing Docker..."
    apt-get install -y docker-ce

    log "Starting Docker service..."
    systemctl start docker
    systemctl enable docker

    log "Docker installed successfully on Ubuntu."
}

# Cài đặt Docker trên RHEL/CentOS
install_docker_rhel_centos() {
    log "Installing prerequisite packages..."
    yum install -y yum-utils device-mapper-persistent-data lvm2

    log "Adding Docker repository..."
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    log "Installing Docker..."
    yum install -y docker-ce

    log "Starting Docker service..."
    systemctl start docker
    systemctl enable docker

    log "Docker installed successfully on RHEL/CentOS."
}

# Hàm cài đặt Docker dựa trên hệ điều hành
install_docker() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID

        case "$OS" in
            ubuntu)
                log "Detected Ubuntu $VERSION_ID."
                install_docker_ubuntu
                ;;
            rhel|centos)
                log "Detected $OS $VERSION_ID."
                install_docker_rhel_centos
                ;;
            *)
                log "Unsupported operating system: $OS. Exiting."
                exit 1
                ;;
        esac
    else
        log "Cannot detect operating system. Exiting."
        exit 1
    fi
}