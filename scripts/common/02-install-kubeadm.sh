#!/usr/bin/env bash
set -euo pipefail

# Install kubeadm, kubelet and kubectl from the official Kubernetes apt repo.

# Dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Latest stable minor version (e.g. v1.34). Override with: K8S_VERSION=v1.34 ./script.sh
K8S_VERSION=${K8S_VERSION:-$(curl -fsSL https://dl.k8s.io/release/stable.txt | grep -oE '^v[0-9]+\.[0-9]+')}

# Kubernetes apt keyring and repo
sudo mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Install kubelet, kubeadm, kubectl
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Hold versions so apt upgrade doesn't break the cluster
sudo apt-mark hold kubelet kubeadm kubectl

# kubelet will restart in a loop until `kubeadm init/join` runs; that's expected
sudo systemctl enable kubelet

echo "kubeadm/kubelet/kubectl installed: $(kubeadm version -o short)"
