#!/bin/bash
# shellcheck disable=SC2034,SC2154

# Image configuration
IMAGE_NAME="debian12-pku-${build_version}.qcow2"
DISK_SIZE="10G"
PACKAGES=(qemu-guest-agent)
SERVICES=(qemu-guest-agent.service)

function pre() {
  cp $COMMON_ROOT/cluster_notifications.sh "${MOUNT}"/etc/profile.d/
 sed -i '/debian-security/!s|http://deb.debian.org/debian|http://mirrors.lcpu.dev/debian|' "${MOUNT}"/etc/apt/sources.list.d/debian.sources

}

function post() {
  # compress the image, which is qcow2 format
  qemu-img convert -c -f qcow2 -O qcow2 "${1}" "${2}"
  rm "${1}"
}