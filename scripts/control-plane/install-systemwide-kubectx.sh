#!/usr/bin/env bash
set -euo pipefail

if ! command -v kubectx > /dev/null 2>&1; then
    sudo apt install kubectx -y
    echo "[INSTALLED] kubectx"
else
    echo "[SKIPPED] kubectx already installed"
fi

