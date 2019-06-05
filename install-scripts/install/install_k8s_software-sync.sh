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
SOFTWARE=/root/software
K8S_PACKAGES_NAME=kubernetes-server-v1.14.2-linux-amd64.tar.gz
ETCD_PACKAGE_NAME=etcd-v3.3.13-linux-amd64.tar.gz
FLANNEL_PACKAGE_NAME=flannel-v0.11.0-linux-amd64.tar.gz
K8S_DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/$K8S_PACKAGES_NAME
ETCD_DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/etcd/$ETCD_PACKAGE_NAME
FLANNEL_DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/network/$FLANNEL_PACKAGE_NAME
M1_K8S_IP=10.10.10.22
M2_K8S_IP=10.10.10.23
M3_K8S_IP=10.10.10.24
W1_K8S_IP=10.10.10.40
W2_K8S_IP=10.10.10.41
W3_K8S_IP=10.10.10.42
H1_LVS_IP=10.10.10.1
H2_LVS_IP=10.10.10.2


### 1.Downloadinstall packages of kubernetes need
rm -rf  $SOFTWARE/*
wget $K8S_DOWNLOAD_URL -P $SOFTWARE
wget $ETCD_DOWNLOAD_URL -P $SOFTWARE
wget $FLANNEL_DOWNLOAD_URL -P $SOFTWARE
	 
	 
### 2.Install ansible package with yum way on devops server and create hosts files for ansible
yum install ansible  -y  >/dev/null 
cat >/etc/ansible/hosts <<"EOF"
[master-k8s-vgs]
master-k8s-n01     ansible_host=${M1_K8S_IP}
master-k8s-n02     ansible_host=${M2_K8S_IP}
master-k8s-n03     ansible_host=${M3_K8S_IP}

[worker-k8s-vgs]
worker-k8s-n01     ansible_host=${W1_K8S_IP}
worker-k8s-n02     ansible_host=${W2_K8S_IP}
worker-k8s-n03     ansible_host=${W3_K8S_IP}

[ha-lvs-vgs]
ha-lvs-n01     ansible_host=${H1_LVS_IP}
ha-lvs-n02     ansible_host=${H2_LVS_IP}
EOF

### 3.sync packages to each server of  kubernetes
#kubernetes packages
ansible master-k8s-vgs -m copy -a "src=${SOFTWARE}/$K8S_PACKAGE_NAME dest=${SOFTWARE}"
ansible worker-k8s-vgs -m copy -a "src=${SOFTWARE}/$K8S_PACKAGE_NAME dest=${SOFTWARE}"

#etcd package
ansible master-k8s-vgs -m copy -a "src=${SOFTWARE}/$ETCD_PACKAGE_NAME dest=${SOFTWARE}"

#flannel package
ansible master-k8s-vgs -m copy -a "src=${SOFTWARE}/$FLANNEL_PACKAGE_NAME dest=${SOFTWARE}"
ansible worker-k8s-vgs -m copy -a "src=${SOFTWARE}/$FLANNEL_PACKAGE_NAME dest=${SOFTWARE}"

