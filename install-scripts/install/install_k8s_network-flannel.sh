#!/bin/bash
#
# Descripts: This is a install script about the k8s cluster !
# Copyright (C) 2001-2018 SIA
#
# INFO:
# touch: It is by Kevin li
# Date:  2016-08-17
# Email: bighank@163.com
# QQ:    2658757934
# blog:  http://home.51cto.com/space?uid=6170059
######################################################################


#################### Variable parameter setting ######################
FANNEL_INSTALL_PATH=/data/apps/k8s/network/flannel
SOFTWARE=/root/software
VERSION=v0.11.0
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/network/flannel-${VERSION}-linux-amd64.tar.gz
FLANNEL_ETCD_ENPOINTS==https://10.10.10.22:2379,https://10.10.10.23:2379,https://10.10.10.24:2379
FLANNEL_ETCD_PREFIX=/k8s/network
CA_PATH=/etc/k8s/ssl
NETWORK_SUBNET=172.16.0.0
TYPE=vxlan

### 1.Check if the install directory exists.
if [ ! -d $FANNEL_INSTALL_PATH/bin ]; then
     mkdir -p $FANNEL_INSTALL_PATH/bin     
fi


### 2.Install flannel of network.
wget $DOWNLOAD_URL -P $SOFTWARE
cd $SOFTWARE
tar zxf flannel-${VERSION}-linux-amd64.tar.gz
mv flannel-${VERSION}-linux-amd64 $FANNEL_INSTALL_PATH/bin


### 3.Install flannel of service .
cat >/usr/lib/systemd/system/flanneld.service<<"EOF"
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=/data/apps/k8s/network/bin/flanneld \
  -etcd-cafile=${CA_PATH}/ca.pem \
  -etcd-certfile=${CA_PATH}/etcd.pem \
  -etcd-keyfile=${CA_PATH}/etcd-key.pem \
  -etcd-endpoints=${FLANNEL_ETCD_ENPOINTE} \
  -etcd-prefix=${FLANNEL_ETCD_PREFIX}\
  -iface=eth0
ExecStartPost=${FANNEL_INSTALL_PATH}/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF


### 3.Create network of flannel .
etcdctl --endpoints=$FANNEL_ETCD_ENPOINTS \
  --ca-file=${CA_PATH}/ca.pem \
  --cert-file=${CA_PATH}/etcd.pem \
  --key-file=${CA_PATH}/etcd-key.pem \
  mkdir $FLANNEL_ETCD_PREFIX
  
etcdctl --endpoints=$FANNEL_ETCD_ENPOINTS \
  --ca-file=${CA_PATH}/ca.pem \
  --cert-file=${CA_PATH}/etcd.pem
  --key-file=${CA_PATH}/etcd-key.pem
  mk $FLANNEL_ETCD_PREFIX/config '{"Network":"${NETWORK_SUBNET}","SubnetLen":24,"Backend":{"Type":"TYPE"}}'
  
  
  