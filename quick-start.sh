#!/bin/bash

# Đường dẫn log
LOG_FILE="/var/log/repo/repo_local.log"
GIT_REPO_URL=https://github.com/hieuny613/repo-local.git
CLONE_DIR="/opt/"
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
    apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    log "Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    log "Updating package database..."
    apt-get update -y

    log "Installing Docker..."
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y 

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
    yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

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
install_git() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID

        case "$OS" in
            ubuntu)
                log "Installing Git on Ubuntu..."
                apt-get update -y
                apt-get install -y git
                ;;
            rhel|centos)
                log "Installing Git on RHEL/CentOS..."
                yum install -y git
                ;;
            *)
                log "Unsupported operating system for Git installation: $OS. Exiting."
                exit 1
                ;;
        esac

        log "Git installed successfully."
    else
        log "Cannot detect operating system. Skipping Git installation."
    fi
}
clone_and_run_docker_compose() {

    if [ -z "$GIT_REPO_URL" ] || [ -z "$CLONE_DIR" ]; then
        log "Git repository URL and clone directory must be provided. Exiting."
        exit 1
    fi

    log "Cloning Git repository from $GIT_REPO_URL..."
    git clone "$GIT_REPO_URL" "$CLONE_DIR"

    if [ $? -ne 0 ]; then
        log "Failed to clone the repository. Exiting."
        exit 1
    fi

    log "Successfully cloned the repository to $CLONE_DIR."

    cd "$CLONE_DIR" || { log "Failed to change directory to $CLONE_DIR. Exiting."; exit 1; }

    log "Running Docker Compose..."
    docker compose up -d

    if [ $? -ne 0 ]; then
        log "Failed to run Docker Compose. Exiting."
        exit 1
    fi

    log "Docker Compose started successfully."
}