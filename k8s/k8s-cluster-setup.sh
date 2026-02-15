#!/bin/bash

echo "=============================="
echo " Kubernetes Cluster Setup "
echo "=============================="

### STEP 1: Update System
sudo yum update -y

### STEP 2: Disable Swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

### STEP 3: Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

### STEP 4: Load Kernel Modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo modprobe br_netfilter

### STEP 5: Sysctl Settings for Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

### STEP 6: Install containerd
sudo yum install -y containerd
sudo systemctl enable containerd
sudo systemctl start containerd

### STEP 7: Configure containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

### STEP 8: Install kubeadm, kubelet, kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet
sudo systemctl start kubelet

echo "=============================="
echo " Common setup completed "
echo "=============================="
echo ""
echo "👉 Run MASTER steps only on Control Plane node"
echo "👉 Run WORKER join command on Worker nodes"

