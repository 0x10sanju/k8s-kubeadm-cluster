# Kubernetes cluster setup (kubeadm + containerd + Calico)

For Ubuntu/Debian nodes. Run the steps in order.

## 1. All nodes (control plane and workers)

```bash
sudo ./scripts/common/01-containerd-install.sh
sudo ./scripts/common/02-install-kubeadm.sh
```

Use the same Kubernetes version on every node. See the header of `02-install-kubeadm.sh` for how to pin it.

## 2. Control plane only

Initialize the cluster:

```bash
sudo kubeadm init
```

Set up kubectl for your normal user (not root):

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install the Calico network plugin (change the version if you want a different one):

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.1/manifests/calico.yaml
```

Wait for the node to show `Ready` (can take a minute or two):

```bash
kubectl get nodes -w
```

### Optional: kubectx and kubens

Quick switching of contexts and namespaces (`kubectx`, `kubens`). Run after the
kubeconfig step above, as your normal user (the script uses sudo itself):

```bash
./scripts/control-plane/install-kubectx.sh
```

Usage:

```bash
kubens kube-system    # switch namespace
kubens -              # back to previous namespace
kubens -c             # print current namespace
kubectx               # list contexts
```

## 3. Workers only

On the control plane, print the join command:

```bash
kubeadm token create --print-join-command
```

Run the printed command on each worker with `sudo`. Then check from the control plane:

```bash
kubectl get nodes
```

All nodes should show `Ready`.

## 4. Optional: metrics-server on dev clusters

If `kubectl top` fails with TLS errors (and metrics-server is already installed):

```bash
./scripts/addons/metrics-server-insecure-tls.sh
```

For dev/lab clusters only, since it disables kubelet certificate verification.

