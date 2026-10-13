#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script as root." >&2
    exit 1
fi

echo
echo "==> Installing Network UPS Tools"

apt-get update

DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        nut-server \
        nut-client \
        nut-snmp \
        snmp

echo
echo "==> NUT packages installed"
