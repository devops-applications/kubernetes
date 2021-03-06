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
# blog:  https://blog.51cto.com/blief
######################################################################


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0

#################### Variable parameter setting ######################
USER=k8s
CLUSTER_INSTALL_DIR=/data/apps/k8s
CA_DIR=/etc/k8s/ssl

# Notice: If you want execute the scripts use  ansible, Please use "#"  annotation  this statement 
read -p "Do you want init for system ,please make sure the operation? please input [y/n]:" STATE


#./start
if [ "$STATE" = "y" ]; then

########## Init settings of system ##########
# Install the system dependencies package.
yum install -y epel-release >>/dev/null 2>&1
yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp ntpdate ntp wget telnet rsync >>/dev/null 2>&1

# Disable the system firewall.
systemctl stop firewalld >>/dev/null 2>&1
systemctl disable firewalld >>/dev/null 2>&1

# Shut down the system swap partition.
swapoff -a  >>/dev/null 2>&1
sed -i 's/.*swap.*/#&/' /etc/fstab

# Disable the system selinux.
setenforce  0 >>/dev/null 2>&1
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux  >>/dev/null 2>&1
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config  >>/dev/null 2>&1
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux >>/dev/null 2>&1
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config  >>/dev/null 2>&1
echo -e ".........................................................................."
echo "INFO: Initialization successd of system ..."

#Add sudo permissions to devops in /etc/sudoers file .
sudo sed -i  "/secure_path/s:\:/usr/local.*::" /etc/sudoers
sudo sed -i  "/secure_path/s:\:/usr/bin:\:/usr/bin\:/usr/local/bin\:/usr/local/sbin:" /etc/sudoers

########## Optimization kernel of system ##########
# Load the Linux kernel module.
sudo modprobe br_netfilter 
sudo modprobe ip_vs
sudo modprobe ip_conntrack 

# Setting kubernetes  kernel parameters.
sudo sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
sudo sed -i '/net.bridge.bridge-nf-call-iptables/d'  /etc/sysctl.conf
sudo sed -i '/net.bridge.bridge-nf-call-ip6tables/d'  /etc/sysctl.conf
sudo sed -i '/net.ipv4.ip_forward/d'  /etc/sysctl.conf
sudo sed -i '/net.ipv4.tcp_tw_recycle/d'  /etc/sysctl.conf
sudo sed -i '/vm.swappiness/d'  /etc/sysctl.conf
sudo sed -i '/vm.overcommit_memory/d'  /etc/sysctl.conf
sudo sed -i '/vm.panic_on_oom/d'  /etc/sysctl.conf
sudo sed -i '/fs.inotify.max_user_watches/d'  /etc/sysctl.conf
sudo sed -i '/fs.file-max/d'  /etc/sysctl.conf
sudo sed -i '/fs.nr_open/d'  /etc/sysctl.conf
sudo sed -i '/net.ipv6.conf.all.disable_ipv6/d'  /etc/sysctl.conf
sudo sed -i '/net.netfilter.nf_conntrack_max/d'  /etc/sysctl.conf
cat >/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720 
EOF
sysctl -p /etc/sysctl.d/kubernetes.conf  >>/dev/null 2>&1

# Disable numa for system.
sudo sed -i "s:numa=off::" /etc/sysconfig/grub
sudo sed -i "s:centos/swap  rhgb:& numa=off:" /etc/sysconfig/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg >>/dev/null 2>&1

# Update kernel of system
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm >>/dev/null 2>&1
yum --enablerepo=elrepo-kernel install -y kernel-lt >>/dev/null 2>&1
sudo grub2-set-default 0 >>/dev/null 2>&1

# Disable useless service of system
systemctl stop postfix>>/dev/null 2>&1  && systemctl disable postfix >>/dev/null 2>&1

# Setting system time zone.
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0
systemctl restart rsyslog 
systemctl restart crond
ntpdate cn.pool.ntp.org >/dev/null 2>&1
ntpdate ntp1.aliyun.com
hwclock -w
echo -e ".........................................................................."
echo "INFO: Set successd of system ..."


############ Check the service running user and working directory. ##############
# create user if not exists
egrep "^$USER" /etc/passwd > /dev/null
if [ $? -ne 0 ]; then
     groupadd $USER
     useradd -g $USER -d /var/lib/k8s -c "Kubernetes Service" -m -s /sbin/nologin  $USER
fi

if  [ ! -d $CLUSTER_INSTALL_DIR ]; then
      mkdir -p  $CLUSTER_INSTALL_DIR 
      if [ ! -d $CA_DIR ]; then
           mkdir -p $CA_DIR
      fi
else
      if [ ! -d $CA_DIR ]; then
           mkdir -p $CA_DIR
      fi
fi


############ Reboot sysytem for update kernel of system . ##############
reboot now

fi
#./End

if [ "$STATE" = "n" ]; then
     exit 0
fi
