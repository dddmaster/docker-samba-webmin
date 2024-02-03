#!/usr/bin/env bash
set -o nounset                              # Treat unset variables as an error
if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    #smbd &
    ionice -c 3 smbd --no-process-group &
    nmbd &
    if [[ -n $HOSTNAME && "$HOSTNAME" != "" ]]; then
        python3 ./wsdd.py -n $HOSTNAME &
        echo "RUNNING ON $HOSTNAME"
    fi

    echo "starting $@"
    exec "$@" &
    tail -f /dev/stdout /var/log/samba/log.smbd /var/log/samba/log.nmbd /var/webmin/webmin.log /var/webmin/miniserv.error
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
fi