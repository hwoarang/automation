#!/bin/bash

SUSEConnect -r ${regcodeSLES}
sleep 1
SUSEConnect -p ses/5/x86_64 -r ${regcodeSES}
sleep 1 

zypper -n in -l -y ntp 

cat <<EOF > /etc/ntp.conf
server ntp1.suse.de
server ntp2.suse.de
server ntp3.suse.de
EOF

cat <<EOF > /etc/ntp.conf
server ntp1.suse.de
server ntp2.suse.de
server ntp3.suse.de
EOF

/usr/bin/systemctl stop SuSEfirewall2.service
/usr/bin/systemctl enable --now ntpd.service

zypper -n in -l -y salt-minion

cat <<EOF > /etc/salt/minion.d/master.conf
master: ${saltmaster}
EOF

systemctl enable salt-minion.service
systemctl start salt-minion.service
