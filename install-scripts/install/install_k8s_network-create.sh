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
FLANNEL_ETCD_PREFIX=/k8s/network
CA_DIR=/etc/k8s/ssl
NETWORK_SUBNET=172.16.0.0
TYPE=vxlan


### Create network subnet of flannel .
etcdctl --endpoints=$FLANNEL_ETCD_ENPOINTS \
  --ca-file=${CA_PATH}/ca.pem \
  --cert-file=${CA_PATH}/etcd.pem \
  --key-file=${CA_PATH}/etcd-key.pem \
  mkdir $FLANNEL_ETCD_PREFIX
  
etcdctl --endpoints=$FLANNEL_ETCD_ENPOINTS \
  --ca-file=${CA_PATH}/ca.pem \
  --cert-file=${CA_PATH}/etcd.pem
  --key-file=${CA_PATH}/etcd-key.pem
  mk $FLANNEL_ETCD_PREFIX/config '{"Network":"${NETWORK_SUBNET}","SubnetLen":24,"Backend":{"Type":"$TYPE"}}'
  
  
  