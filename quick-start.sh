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
