#!/bin/bash
# shellcheck disable=SC2034,SC2154

# Image configuration
IMAGE_NAME="ubuntu20.04-server-pku-${build_version}.qcow2"
DISK_SIZE="10G"
PACKAGES=(qemu-guest-agent)
SERVICES=(qemu-guest-agent.service)

function pre() {
  cp $COMMON_ROOT/cluster_notifications.sh "${MOUNT}"/etc/profile.d/
  sed -i 's|http://%(availability_zone)s.clouds.archive.ubuntu.com/ubuntu/|https://mirrors.lcpu.dev/ubuntu/|g' "${MOUNT}"/etc/cloud/cloud.cfg
  sed -i 's|http://security.ubuntu.com/ubuntu|https://mirrors.lcpu.dev/ubuntu|g' "${MOUNT}"/etc/cloud/cloud.cfg
  sed -i 's|http://archive.ubuntu.com/ubuntu|https://mirrors.lcpu.dev/ubuntu|g' "${MOUNT}"/etc/cloud/cloud.cfg
}

function post() {
  # compress the image, which is qcow2 format
  qemu-img convert -c -f qcow2 -O qcow2 "${1}" "${2}"
  rm "${1}"
}