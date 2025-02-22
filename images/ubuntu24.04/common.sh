#!/bin/bash
# Common functions for Ubuntu images

DISTRO="ubuntu24.04"
IMAGE_NAME="${DISTRO}-base.img"
BASE_IMAGE="${BASE_DIR}/${IMAGE_NAME}"

# Download the Ubuntu cloud image
# ${1} - Base directory to store the image
# ${2} - Distribution (should be "ubuntu")
# ${3} - Flavor (server, minimal, etc.)
function download_source() {
  
  # Skip if the image already exists
  if [ -f "${BASE_IMAGE}" ]; then
    echo "Base image already exists at ${BASE_IMAGE}, skipping download."
    return 0
  fi
  
  echo "Downloading Ubuntu cloud image for ${flavor}..."
  
  # Different URLs based on flavor
  wget -q -O "${BASE_IMAGE}" "https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/noble/current/noble-server-cloudimg-amd64.img" 
  
  # Ubuntu cloud images are typically in qcow2 format already
  echo "Download complete: ${BASE_IMAGE}"
  return 0
}

# Function to resize Ubuntu cloud image
function resize_image() {
  local image_path="${1}"
  local new_size="${2}"
  
  # ubuntu cloud images are already in qcow2 format, partition table:
  # /dev/nbd0p1  2099200 7339998 5240799  2.5G Linux filesystem
  # /dev/nbd0p14    2048   10239    8192    4M BIOS boot
  # /dev/nbd0p15   10240  227327  217088  106M EFI System
  # /dev/nbd0p16  227328 2097152 1869825  913M Linux extended boot

  # Resize the image to the new size
  echo "Resizing image to ${new_size}..."
  qemu-img resize "${image_path}" "${new_size}"

  # Use qemu-nbd to access the partitions
  echo "Connecting image to NBD device..."
  # Find an unused nbd device
  modprobe nbd max_part=16
  
  # Find the first available nbd device
  NBD_DEV=$(find_free_nbd)
  
  # Connect the image to the NBD device
  qemu-nbd --connect="${NBD_DEV}" "${image_path}"
  
  # Wait for partitions to be recognized
  sleep 2
  partprobe "${NBD_DEV}"
  
  # Resize the filesystem
  echo "Resizing filesystem on ${NBD_DEV}p1..."
  sgdisk --move-second-header "${NBD_DEV}"
  e2fsck -f "${NBD_DEV}p1"
  resize2fs "${NBD_DEV}p1"
  
  # Disconnect the NBD device
  echo "Disconnecting NBD device..."
  qemu-nbd --disconnect "${NBD_DEV}"
  
  echo "Resize complete."
}

function os_update() {
  echo "DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"
}

# Function to install packages on Ubuntu
function os_install() {
  echo "DEBIAN_FRONTEND=noninteractive apt-get install -y"
}

function os_cleanup() {
  echo "DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && DEBIAN_FRONTEND=noninteractive apt-get clean"
}

function mount_image() {
  NBD_DEV=$(find_free_nbd)
  qemu-nbd --connect="${NBD_DEV}" "${1:-${IMAGE}}"
    wait_until_settled "${NBD_DEV}"
  
  # Mount partitions
  mount "${NBD_DEV}p1" "${MOUNT}"
  mount "${NBD_DEV}p16" "${MOUNT}/boot"
  mount "${NBD_DEV}p15" "${MOUNT}/boot/efi"
}

function unmount_image() {
  umount "${MOUNT}/boot/efi"
  umount "${MOUNT}/boot"
  umount "${MOUNT}"
  qemu-nbd --disconnect "${NBD_DEV}"
}