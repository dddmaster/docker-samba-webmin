#!/bin/sh

if [ '$@' ]
then
    echo "starting $@"
    exec "$@" &
fi

/etc/webmin/start --nofork &
ionice -c 3 smbd --no-process-group &
nmbd &

if [[ -n $HOSTNAME && "$HOSTNAME" != "" ]]; then
    python3 ./wsdd.py -n $HOSTNAME &
    echo "RUNNING ON $HOSTNAME"
fi
tail -f /dev/stdout /var/log/samba/log.smbd /var/log/samba/log.nmbd /var/webmin/webmin.log /var/webmin/miniserv.error