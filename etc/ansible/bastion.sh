#!/bin/bash

# This script is used to setup a host to act as a "bastion" from where the OCP advanced installer can be run and to serve NFS volumes
# Register to Red Hat with "subscription-manager register" and attach a suitable subscription before running this script

echo "Setup repositories..."
subscription-manager repos --disable '*'
subscription-manager repos --enable='rhel-7-server-rpms' --enable='rhel-7-server-extras-rpms' --enable='rhel-7-server-ose-3.3-rpms'
subscription-manager repos --list-enabled
yum clean all

echo "Update and install correct packages..."
yum -y update
yum -y install vim ntp wget git net-tools bind-utils iptables-services bridge-utils bash-completion

echo "Start and enable services..."
systemctl start ntpd
systemctl enable ntpd
systemctl start iptables
systemctl enable iptables

echo "Setup NFS server..."
iptables -I INPUT 1 -p tcp --dport 2049 -j ACCEPT
service iptables save
yum -y install nfs-utils rpcbind

mkdir -p /srv/nfs/{registry,metrics,logging,vol1,vol2,vol3}
chmod -R 777 /srv/nfs/*
chown -R nfsnobody:nfsnobody /srv/nfs

echo "Setting up exports..."
cat << EOF > /etc/exports
/srv/nfs/registry *(rw,root_squash,no_wdelay)
/srv/nfs/metrics *(rw,root_squash,no_wdelay)
/srv/nfs/logging *(rw,root_squash,no_wdelay)
/srv/nfs/vol1 *(rw,root_squash,no_wdelay)
/srv/nfs/vol2 *(rw,root_squash,no_wdelay)
/srv/nfs/vol3 *(rw,root_squash,no_wdelay)
EOF

systemctl restart nfs nfs-server nfs-lock nfs-idmap rpcbind
systemctl enable nfs nfs-server nfs-lock nfs-idmap rpcbind

setsebool -P virt_use_nfs=true

yum -y install atomic-openshift-utils

