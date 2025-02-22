#!/bin/bash
# Common functions for Ubuntu images

DISTRO="almalinux8.10"
IMAGE_NAME="${DISTRO}-base.qcow2"
BASE_IMAGE="${BASE_DIR}/${IMAGE_NAME}"
DISK_SIZE="15G"

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
  wget -q -O "${BASE_IMAGE}" "https://mirrors.pku.edu.cn/almalinux/8.10/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2" 
  
  # Ubuntu cloud images are typically in qcow2 format already
  echo "Download complete: ${BASE_IMAGE}"
  return 0
}

# Function to resize Ubuntu cloud image
function resize_image() {
  local image_path="${1}"
  local new_size="${2}"
  
  # almalinux partition layout
  # /dev/nbd2p1    2048     4095     2048    1M BIOS boot
  # /dev/nbd2p2    4096   413695   409600  200M EFI System
  # /dev/nbd2p3  413696  2510847  2097152    1G Linux filesystem
  # /dev/nbd2p4 2510848 20969471 18458624  8.8G Linux filesystem

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

  sgdisk -e "${NBD_DEV}"
  
  # Resize the filesystem
  echo "Resizing filesystem on ${NBD_DEV}p1..."
  # fix gpt partition table
  # resize partition
  parted -s "${NBD_DEV}" resizepart 4 100%
  fdisk -l "${NBD_DEV}"
  mount "${NBD_DEV}p4" "${MOUNT}"
  # resize filesystem
  xfs_growfs "${NBD_DEV}p4"
  umount "${MOUNT}"
  fdisk -l "${NBD_DEV}"
  
  # Disconnect the NBD device
  echo "Disconnecting NBD device..."
  qemu-nbd --disconnect "${NBD_DEV}"
  
  echo "Resize complete."
}

function os_update() {
  echo "dnf update -y"
}

# Function to install packages on Ubuntu
function os_install() {
  echo "dnf install -y"
}

function os_cleanup() {
  echo "dnf clean all"
}

function mount_image() {
  NBD_DEV=$(find_free_nbd)
  qemu-nbd --connect="${NBD_DEV}" "${1:-${IMAGE}}"
  sleep 2
  
  # Mount partitions
  mount "${NBD_DEV}p4" "${MOUNT}"
  mount "${NBD_DEV}p3" "${MOUNT}/boot"
  mount "${NBD_DEV}p2" "${MOUNT}/boot/efi"
}

function unmount_image() {
  sync "${MOUNT}"
  umount "${MOUNT}/boot/efi"
  umount "${MOUNT}/boot"
  umount "${MOUNT}"
  qemu-nbd --disconnect "${NBD_DEV}"
}
