#!/bin/bash
# shellcheck disable=SC2034,SC2154

# Image configuration
IMAGE_NAME="ubuntu24.04-server-pku-${build_version}.qcow2"
DISK_SIZE="10G"
PACKAGES=(qemu-guest-agent)
SERVICES=()

function pre() {
  sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.pku.edu.cn@g' "${MOUNT}"/etc/apt/sources.list.d/ubuntu.sources
  sudo sed -i 's@//.*security.ubuntu.com@//mirrors.pku.edu.cn@g' "${MOUNT}"/etc/apt/sources.list.d/ubuntu.sources
  sudo sed -i 's@//.*clouds.archive.ubuntu.com@//mirrors.pku.edu.cn@g' "${MOUNT}"/etc/apt/sources.list.d/ubuntu.sources
}

function post() {
  # Convert raw image to qcow2 format
  qemu-img convert -c -f raw -O qcow2 "${1}" "${2}"
  rm "${1}"
}