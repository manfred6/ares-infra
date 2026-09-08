#!/bin/bash

set -euo pipefail

mkdir -p .secrets
chmod 700 .secrets

if [[ ! -f .secrets/resolute-ed25519 ]]; then
    ssh-keygen \
        -t ed25519 \
        -N "" \
        -C "packer-resolute-temp" \
        -f .secrets/resolute-ed25519
fi
