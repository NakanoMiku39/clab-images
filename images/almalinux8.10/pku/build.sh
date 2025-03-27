#!/bin/bash
# shellcheck disable=SC2034,SC2154

# Image configuration
IMAGE_NAME="almalinux8.10-pku-${build_version}.qcow2"
DISK_SIZE="15G"
PACKAGES=()
SERVICES=()

function pre() {
  cp $COMMON_ROOT/cluster_notifications.sh "${MOUNT}"/etc/profile.d/
  sed -e 's|^mirrorlist=|#mirrorlist=|g' -id   -i.bak  -e 's|^# baseurl=https://repo.almalinux.org|baseurl=https://mirrors.pku.edu.cn|g' \
    "${MOUNT}"/etc/yum.repos.d/almalinux.repo    "${MOUNT}"/etc/yum.repos.d/almalinux-powertools.repo
}

function post() {
  # Convert raw image to qcow2 format
  qemu-img convert -c -f qcow2 -O qcow2 "${1}" "${2}"
  rm "${1}"
}