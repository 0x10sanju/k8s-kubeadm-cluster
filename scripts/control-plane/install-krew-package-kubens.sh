#!/usr/bin/env bash
set -euo pipefail

echo "Checking whether krew is installed..."
kubectl krew version

kubectl krew install ns ctx tree

echo "[INSTALLED] ns"
echo "Run it with 'kubectl ns'"

echo "[INSTALLED] ctx"
echo "Run it with 'kubectl ctx'"

echo "[INSTALLED] tree"
echo "Run it with 'kubectl tree <resource-type> <resource-name>'"

