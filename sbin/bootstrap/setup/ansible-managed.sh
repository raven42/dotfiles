#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script as root." >&2
    exit 1
fi

echo
echo "==> Installing Ansible managed-host prerequisites"

apt-get update

DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        openssh-server \
        python3 \
        python3-apt \
        sudo

systemctl enable --now ssh

echo
echo "==> Ansible managed-host prerequisites installed"
