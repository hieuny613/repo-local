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

# Kiểm tra và cài đặt rclone
install_rclone() {
    if command -v rclone &> /dev/null; then
        log "Rclone is already installed. Skipping installation."
    else
        log "Rclone is not installed. Starting installation..."
        if curl https://rclone.org/install.sh | sudo bash; then
            log "Rclone installed successfully."
        else
            log "Failed to install rclone."
            exit 1
        fi
    fi
}

# Cấu hình rclone remote cho Ubuntu và EPEL mirrors
configure_rclone() {
    log "Configuring rclone remotes..."
    mkdir -p ~/.config/rclone
    cat <<EOL > ~/.config/rclone/rclone.conf
[mirror-ubuntu]
type = http
url = https://mirror.xtom.com.hk/ubuntu
[mirror-epel7]
type = http
url = https://dl.fedoraproject.org/pub/archive/epel
[mirror-epel]
type = http
url = http://ftp.iij.ad.jp/pub/linux/Fedora/epel
EOL

    chmod 600 ~/.config/rclone/rclone.conf
    log "Rclone remotes configured."
}

# Tạo thư mục cho repo Ubuntu và EPEL
create_directories() {
    log "Creating directories for repos..."
    mkdir -p /repo/ubuntu/dists
    mkdir -p /repo/epel/7/x86_64
    mkdir -p /repo/epel/8/x86_64
    mkdir -p /repo/epel/9/x86_64
}

# Hàm kéo repo với rclone
sync_repo() {
    local remote_path="$1"
    local local_path="$2"
    log "Starting sync: $remote_path to $local_path"
    if rclone sync "$remote_path" "$local_path" --transfers 20 --checkers 20 2>&1 | tee -a "$LOG_FILE"; then
        log "Sync completed: $remote_path to $local_path"
    else
        log "Sync failed: $remote_path to $local_path"
    fi
}

# Kéo repo Ubuntu
sync_ubuntu_repos() {
    log "Syncing Ubuntu repositories..."
    sync_repo "mirror-ubuntu:dists/bionic" "/repo/ubuntu/dists/"
    sync_repo "mirror-ubuntu:dists/bionic-backports" "/repo/ubuntu/dists/"
    sync_repo "mirror-ubuntu:dists/bionic-proposed" "/repo/ubuntu/dists/"
    sync_repo "mirror-ubuntu:dists/bionic-security" "/repo/ubuntu/dists/"
    sync_repo "mirror-ubuntu:dists/bionic-updates" "/repo/ubuntu/dists/"

    sync_repo "mirror-ubuntu:dists/focal" "/repo/ubuntu/dists/"
    sync_repo "mirror-ubuntu:dists/focal-backports" "/repo/ubuntu/dists/focal-backports"
    sync_repo "mirror-ubuntu:dists/focal-proposed" "/repo/ubuntu/dists/focal-proposed"
    sync_repo "mirror-ubuntu:dists/focal-security" "/repo/ubuntu/dists/focal-security"
    sync_repo "mirror-ubuntu:dists/focal-updates" "/repo/ubuntu/dists/focal-updates"

    sync_repo "mirror-ubuntu:dists/jammy" "/repo/ubuntu/dists/"
    sync_repo "mirror-ubuntu:dists/jammy-backports" "/repo/ubuntu/dists/jammy-backports"
    sync_repo "mirror-ubuntu:dists/jammy-proposed" "/repo/ubuntu/dists/jammy-proposed"
    sync_repo "mirror-ubuntu:dists/jammy-security" "/repo/ubuntu/dists/jammy-security"
    sync_repo "mirror-ubuntu:dists/jammy-updates" "/repo/ubuntu/dists/jammy-updates"

    sync_repo "mirror-ubuntu:dists/mantic" "/repo/ubuntu/dists/"
    sync_repo "mirror-ubuntu:dists/mantic-backports" "/repo/ubuntu/dists/mantic-backports"
    sync_repo "mirror-ubuntu:dists/mantic-proposed" "/repo/ubuntu/dists/mantic-proposed"
    sync_repo "mirror-ubuntu:dists/mantic-security" "/repo/ubuntu/dists/mantic-security"
    sync_repo "mirror-ubuntu:dists/mantic-updates" "/repo/ubuntu/dists/mantic-updates"

    sync_repo "mirror-ubuntu:indices" "/repo/ubuntu/"
    sync_repo "mirror-ubuntu:pool" "/repo/ubuntu/"
    sync_repo "mirror-ubuntu:project" "/repo/ubuntu/"
    sync_repo "mirror-ubuntu:ls-lR.gz" "/repo/ubuntu/"
}

# Kéo repo EPEL
sync_epel_repos() {
    log "Syncing EPEL repositories..."
    sync_repo "mirror-epel7:7/x86_64/" "/repo/epel/7/x86_64/"
    sync_repo "mirror-epel:8/Everything/x86_64" "/repo/epel/8/x86_64/"
    sync_repo "mirror-epel:9/Everything/x86_64" "/repo/epel/9/x86_64/"
}

# Hàm main
main() {
    check_root
    install_rclone
    configure_rclone
    create_directories
    sync_ubuntu_repos
    sync_epel_repos
    log "All repositories have been successfully synced."
}

# Gọi hàm main
main
