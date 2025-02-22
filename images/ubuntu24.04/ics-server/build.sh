#!/bin/bash
# shellcheck disable=SC2034,SC2154

# Image configuration
IMAGE_NAME="ics-server-${build_version}.qcow2"
BASE_IMAGE=$(ls -t ${ORIG_PWD}/output/ubuntu24.04-server-pku-*.qcow2 | head -n 1)
DISK_SIZE="10G"
PACKAGES=(build-essential)
SERVICES=(unattended-upgrades.service)

function pre() {
  cp ${FLAVOR_ROOT}/lcpu.sources ${MOUNT}/etc/apt/sources.list.d/
  cp ${FLAVOR_ROOT}/90_apt.cfg ${MOUNT}/etc/cloud/cloud.cfg.d/
  arch-chroot "${MOUNT}" sh -c "$(os_update)"
  arch-chroot "${MOUNT}" sh -c "$(os_install) lcpu ics-deps unattended-upgrades"
}

function post() {
  # Convert raw image to qcow2 format
  qemu-img convert -c -f qcow2 -O qcow2 "${1}" "${2}"
  rm "${1}"
}