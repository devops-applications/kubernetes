#!/bin/bash
#
# Descripts: This is a install script about the k8s cluster !
# Copyright (C) 2001-2018 Redis SIA
#
# INFO:
# touch: It is by Kevin li
# Date:  2016-08-17
# Email: bighank@163.com
# QQ:    2658757934
# blog:  https://blog.51cto.com/blief
######################################################################


#################### Variable parameter setting ######################
KUBE_NAME=kube-scheduler
K8S_INSTALL_PATH=/data/apps/k8s/kubernetes
K8S_BIN_PATH=${K8S_INSTALL_PATH}/sbin
K8S_LOG_DIR=${K8S_INSTALL_PATH}/logs
K8S_CONF_PATH=/etc/k8s/kubernetes
KUBE_CONFIG_PATH=/etc/k8s/kubeconfig
CA_DIR=/etc/k8s/ssl
SOFTWARE=/root/software
VERSION=v1.14.2
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/kubernetes-server-${VERSION}-linux-amd64.tar.gz
ETH_INTERFACE=eth1
LISTEN_IP=$(ifconfig | grep -A 1 ${ETH_INTERFACE} |grep inet |awk '{print $2}')
USER=k8s


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0
### 1.Check if the install directory exists.
     mkdir -p $K8S_BIN_PATH
fi

if [ ! -d "$K8S_LOG_DIR/$KUBE_NAME" ]; then
     mkdir -p $K8S_LOG_DIR/$KUBE_NAME
fi

if [ ! -d "$K8S_CONF_PATH" ]; then
     mkdir -p $K8S_CONF_PATH
fi

if [ ! -d "$KUBE_CONFIG_PATH" ]; then
     mkdir -p $KUBE_CONFIG_PATH
fi


### 2.Install kube-scheduler binary of kubernetes.
if [ ! -f "$SOFTWARE/kubernetes-server-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE >>/tmp/install.log  2>&1
fi
cd $SOFTWARE && tar -xzf kubernetes-server-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$KUBE_NAME $K8S_BIN_PATH
ln -sf  $K8S_BIN_PATH/${KUBE_NAME} /usr/local/bin
chown -R $USER:$USER $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH


### 3.Create configure file of kube-scheduler.
cat >${K8S_CONF_PATH}/kube-scheduler.yaml<<EOF
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
bindTimeoutSeconds: 600
clientConnection:
  burst: 200
  kubeconfig: "${KUBE_CONFIG_PATH}/${KUBE_NAME}.kubeconfig"
  qps: 100
enableContentionProfiling: false
enableProfiling: true
hardPodAffinitySymmetricWeight: 1
healthzBindAddress: 127.0.0.1:10251
leaderElection:
  leaderElect: true
metricsBindAddress: 127.0.0.1:10251
EOF


### 4.Install the kube-scheduler service.
cat >/usr/lib/systemd/system/${KUBE_NAME}.service<<EOF
[Unit]
Description=Kubernetes kube-scheduler Service
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
User=${USER}
WorkingDirectory=${K8S_INSTALL_PATH}
ExecStart=${K8S_BIN_PATH}/${KUBE_NAME} \\
  --config=/etc/k8s/kubernetes/kube-scheduler.yaml \\
  --bind-address=${LISTEN_IP} \\
  --secure-port=10259 \\
  --tls-cert-file=${CA_DIR}/kube-scheduler.pem \\
  --tls-private-key-file=${CA_DIR}/kube-scheduler-key.pem \\
  --kubeconfig=${KUBE_CONFIG_PATH}/${KUBE_NAME}.kubeconfig \\
  --authentication-kubeconfig=${KUBE_CONFIG_PATH}/${KUBE_NAME}.kubeconfig \\
  --authorization-kubeconfig=${KUBE_CONFIG_PATH}/${KUBE_NAME}.kubeconfig \\
  --client-ca-file=${CA_DIR}/ca.pem \\
  --requestheader-allowed-names="" \\
  --requestheader-client-ca-file=${CA_DIR}/ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --leader-elect=true \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_LOG_DIR}/${KUBE_NAME} \\
  --v=2

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
