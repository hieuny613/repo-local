#!/bin/bash
bash /script/rsync-repo-redhat.sh
exec /usr/sbin/crond -n
