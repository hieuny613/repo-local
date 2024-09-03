#!/bin/bash

# Define an associative array with repos and their corresponding paths
declare -A repos
repos=(
    ["rhel-8-for-x86_64-appstream-rpms"]="/redhat/8/"
    ["rhel-8-for-x86_64-baseos-rpms"]="/redhat/8/"
)

# Log file path
LOG_FILE="/var/log/repo/repo_local.log"

# Function to write log entries with timestamp
log() {
    echo "$(date +'%d-%m-%YT%H:%M:%S') - $1" >> ${LOG_FILE}
}

# Function to sync repo, create metadata, and update updateinfo.xml file
sync_repo() {
    local repoid="$1"
    local base_path="$2"
    local repo_path="${base_path}${repoid}/"

    {
        log "Starting sync for repo: $repoid"

        # Run reposync
        reposync --repoid="$repoid" -p "$base_path" --downloadcomps --download-metadata

        # Change to repo directory
        cd "$repo_path" || { echo "Failed to change directory to $repo_path" >> ${LOG_FILE}; exit 1; }

        # Create metadata for the repo
        createrepo -v "$repo_path" -g comps.xml

        # Remove old updateinfo files
        rm -rf "${repo_path}repodata/*updateinfo*"

        # Copy new updateinfo files
        cp /var/cache/dnf/"$repoid"-*/repodata/*-updateinfo.xml.gz "${repo_path}repodata/"

        # Decompress updateinfo files
        gzip -d "${repo_path}repodata/*-updateinfo.xml.gz"

        # Rename updateinfo file
        mv "${repo_path}repodata/*-updateinfo.xml" "${repo_path}repodata/updateinfo.xml"

        # Modify repo metadata
        modifyrepo "${repo_path}repodata/updateinfo.xml" "${repo_path}repodata/"

        log "Finished sync for repo: $repoid"
    }
}

export -f sync_repo log
export LOG_FILE

# Generate the list of repos and paths
for repoid in "${!repos[@]}"; do
    echo "$repoid ${repos[$repoid]}"
done > repo_list.txt

log "Starting repo sync"

# Run sync_repo in parallel for each repo
parallel --no-notice --colsep ' ' sync_repo {1} {2} :::: repo_list.txt

# Remove temporary file
rm repo_list.txt

log "All repos have been synced and processed!"
