#!/usr/bin/env bash
set -euo pipefail

echo "Make sure the kubectl krew command is installed"
echo "If not, run the 'install-krew.sh' script"

kubectl krew install ns

echo "[INSTALLED] ns"
echo "Run it with 'kubectl ns'"

