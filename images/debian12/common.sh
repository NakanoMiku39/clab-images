#!/bin/bash
# Common functions for Ubuntu images

DISTRO="debian12"
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
  wget -q -O "${BASE_IMAGE}" "https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2" 
  
  # Ubuntu cloud images are typically in qcow2 format already
  echo "Download complete: ${BASE_IMAGE}"
  return 0
}

# Function to resize Ubuntu cloud image
function resize_image() {
  local image_path="${1}"
  local new_size="${2}"
  
  # ubuntu cloud images are already in qcow2 format, partition table:
  # /dev/nbd0p1  262144 6289407 6027264  2.9G Linux root (x86-64)
  # /dev/nbd0p14   2048    8191    6144    3M BIOS boot
  # /dev/nbd0p15   8192  262143  253952  124M EFI System

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
  # fix gpt partition table
  sgdisk -e "${NBD_DEV}"
  # resize partition
  parted "${NBD_DEV}" resizepart 1 100%
  fdisk -l "${NBD_DEV}"
  # resize filesystem
  e2fsck -f "${NBD_DEV}p1"
  resize2fs "${NBD_DEV}p1"
  fdisk -l "${NBD_DEV}"
  
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
  sleep 2

  # Mount partitions
  mount "${NBD_DEV}p1" "${MOUNT}"
  mount "${NBD_DEV}p15" "${MOUNT}/boot/efi"
}

function unmount_image() {
  sync "${MOUNT}"
  umount "${MOUNT}/boot/efi"
  umount "${MOUNT}"
  qemu-nbd --disconnect "${NBD_DEV}"
}
