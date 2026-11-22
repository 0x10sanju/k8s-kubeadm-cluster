#!/usr/bin/env bash
set -euo pipefail

# Prepare a node for Kubernetes: swap off, kernel modules, sysctls, containerd.

# Disable swap now and keep it off after reboot
# (comments out any fstab line whose 3rd column is "swap")
sudo swapoff -a
[ -f /etc/fstab.bak ] || sudo cp /etc/fstab /etc/fstab.bak
sudo awk '{
  line = $0
  sub(/^[[:space:]]*/, "", line)
  if (line ~ /^#/) { print $0; next }
  if ($3 == "swap") { print "#" $0; next }
  print $0
}' /etc/fstab.bak | sudo tee /etc/fstab > /dev/null

# Kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
EOF

# Networking sysctls
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system > /dev/null

# containerd with systemd cgroups
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable containerd
sudo systemctl restart containerd

# Verify
sudo systemctl is-active --quiet containerd && echo "containerd running"
