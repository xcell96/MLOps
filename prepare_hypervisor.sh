#!/usr/bin/env bash

set -euo pipefail

POOL_NAME="base"
POOL_DIR="/var/lib/libvirt/images/base"
IMAGE_FILE="${POOL_DIR}/rocky-base.qcow2"

if ! command -v virsh >/dev/null 2>&1; then
    echo "[-] libvirt does not appear to be installed (virsh not found)"
    exit 1
else
    echo "[+] libvirt is installed (virsh exists)"
fi

mkdir -p "$POOL_DIR"

if ! virsh pool-info "$POOL_NAME" >/dev/null 2>&1; then
    virsh pool-define-as \
        --name "$POOL_NAME" \
        --type dir \
        --target "$POOL_DIR"

    virsh pool-build "$POOL_NAME"
    virsh pool-start "$POOL_NAME"
    virsh pool-autostart "$POOL_NAME"

    echo "[+] Created pool 'base'!"
else
    echo "[+] Pool 'base' already exists..."
fi

if [[ ! -f "$IMAGE_FILE" ]]; then
    curl -L -o "$IMAGE_FILE" \
        https://dl.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2 &&
        echo "[+] Downloaded Rocky base image!"
else
    echo "[+] Rocky base image already exists; skipping download..."
fi

virsh pool-refresh "$POOL_NAME"

virsh pool-list --all

echo "[+] Pool 'base' is ready."
