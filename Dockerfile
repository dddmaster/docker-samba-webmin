FROM alpine
LABEL "traefik.http.services.samba.loadbalancer.server.port"="10000"
RUN apk upgrade && \
    apk update && \
	apk add --no-cache ca-certificates openssl perl perl-net-ssleay expect curl bash samba shadow tini procps python3 && \
	mkdir -p /opt && \
	cd /opt && \
    webmin_version=$(curl -s https://raw.githubusercontent.com/webmin/webmin/master/version) && \
	wget -q -O - "https://prdownloads.sourceforge.net/webadmin/webmin-$webmin_version.tar.gz" | tar xz && \
	ln -sf /opt/webmin-$webmin_version /opt/webmin && \	
    adduser -D -G users -H -S -g 'Samba User' -h /tmp smbuser && \
    file="/etc/samba/smb.conf" && \
    sed -i 's|^;* *\(log file = \).*|   \1/dev/stdout|' $file && \
    sed -i 's|^;* *\(load printers = \).*|   \1no|' $file && \
    sed -i 's|^;* *\(printcap name = \).*|   \1/dev/null|' $file && \
    sed -i 's|^;* *\(printing = \).*|   \1bsd|' $file && \
    sed -i 's|^;* *\(unix password sync = \).*|   \1no|' $file && \
    sed -i 's|^;* *\(preserve case = \).*|   \1yes|' $file && \
    sed -i 's|^;* *\(short preserve case = \).*|   \1yes|' $file && \
    sed -i 's|^;* *\(default case = \).*|   \1lower|' $file && \
    sed -i '/Share Definitions/,$d' $file && \
    echo '   socket options = TCP_NODELAY IPTOS_LOWDELAY ' >>$file && \
    echo '   dead time = 15                     # Default is 0' >>$file && \
    echo '   getwd cache = yes' >>$file && \
    echo '   auto services = global' >>$file && \
    echo '   read raw = yes' >>$file && \
    echo '   write raw = yes' >>$file && \
    echo '   pam password change = yes' >>$file && \
    echo '   map to guest = Bad Password' >>$file && \
    echo '   browsable = yes' >>$file && \
    echo '   guest ok = yes' >>$file && \
    echo '   guest account = root' >>$file && \
    echo '   create mask = 0664' >>$file && \
    echo '   force create mode = 0664' >>$file && \
    echo '   directory mask = 0775' >>$file && \
    echo '   force directory mode = 0775' >>$file && \
    echo '   force user = root' >>$file && \
    echo '   follow symlinks = yes' >>$file && \
    echo '   load printers = no' >>$file && \
    echo '   printing = bsd' >>$file && \
    echo '   printcap name = /dev/null' >>$file && \
    echo '   disable spoolss = yes' >>$file && \
    echo '   strict locking = no' >>$file && \
    echo '   vfs objects = acl_xattr catia fruit recycle streams_xattr' >>$file && \
    echo '   recycle:keeptree = yes' >>$file && \
    echo '   recycle:versions = yes' >>$file && \
    echo '   client ipc max protocol = default' >>$file && \
    echo '   client max protocol = default' >>$file && \
    echo '   server max protocol = SMB3' >>$file && \
    echo '   client ipc min protocol = default' >>$file && \
    echo '   client min protocol = CORE' >>$file && \
    echo '   server min protocol = NT1' >>$file && \
    echo '   durable handles = yes' >>$file && \
    echo '   kernel oplocks = no' >>$file && \
    echo '   kernel share modes = no' >>$file && \
    echo '   posix locking = no' >>$file && \
    echo '   smb2 leases = yes' >>$file && \
    echo '' >>$file && \
    rm -rf /tmp/*
WORKDIR	/opt/webmin
COPY conf/setup.exp samba.sh /usr/bin/
EXPOSE 137/udp 138/udp 139 445 10000

HEALTHCHECK --interval=60s --timeout=15s \
             CMD smbclient -L '\\localhost' -U '%' -m SMB3

RUN /usr/bin/expect /usr/bin/setup.exp && \
	rm /usr/bin/setup.exp && \
	chmod 665 /usr/bin/samba.sh && \
	apk del expect && \
	wget -q https://raw.githubusercontent.com/christgau/wsdd/master/src/wsdd.py && \
    rm -rf $(ls -d */ | grep -v -i -E "theme|acl|cron|samba|webmin|lang|proc$|package-updates|software|system-status|vendor_perl") && \
    rm -rf $(ls -d */ | grep -w -i -E "cluster") && \
    sed -r 's/(smb_conf=)(.*)/\1\/etc\/samba\/smb.conf/g' /etc/webmin/samba/config && \
    cd /etc/webmin && \
    rm -rf $(ls -d */ | grep -v -i -E "theme|acl|cron|samba|webmin|lang|proc$|package-updates|software|system-status|vendor_perl") && \
    rm -rf $(ls -d */ | grep -w -i -E "cluster") && \
    cd /opt/webmin
VOLUME	["/etc/webmin" , "/var/webmin" , "/etc/samba"]
CMD ["/etc/webmin/start", "--nofork"] 
ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/samba.sh"]
	
