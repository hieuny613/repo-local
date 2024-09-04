#!/bin/bash
bash /script/rsync-repo-redhat.sh
bash /script/rsync-repo-ubuntu-epel.sh
exec /usr/sbin/crond -n
