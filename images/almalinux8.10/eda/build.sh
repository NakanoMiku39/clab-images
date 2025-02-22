#!/bin/bash
# shellcheck disable=SC2034,SC2154

# Image configuration
IMAGE_NAME="almalinux8.10-eda-${build_version}.qcow2"
BASE_IMAGE=$(ls -t ${ORIG_PWD}/output/almalinux8.10-pku-*.qcow2 | head -n 1)
DISK_SIZE="150G"
PACKAGES=(redhat-lsb-core libXScrnSaver libnsl libpng12)
SERVICES=(lmg.service)

function pre() {
  mkdir -p "${MOUNT}"/home/almalinux/.config/shadowdesk
  cp -p ${FLAVOR_ROOT}/rpmfusion.repo "${MOUNT}"/etc/yum.repos.d/ && chmod 644 "${MOUNT}"/etc/yum.repos.d/rpmfusion.repo
  cp -p ${FLAVOR_ROOT}/backend.env "${MOUNT}"/home/almalinux/.config/shadowdesk/ && chmod 644 "${MOUNT}"/home/almalinux/.config/shadowdesk/backend.env
  chown -R 1000:1000 "${MOUNT}"/home/almalinux/.config
  cp -p ${FLAVOR_ROOT}/*.service "${MOUNT}"/etc/systemd/system/ && chmod 644 "${MOUNT}"/etc/systemd/system/*.service
  cp -p ${FLAVOR_ROOT}/.bashrc "${MOUNT}"/home/almalinux/ && chown 1000:1000 "${MOUNT}"/home/almalinux/.bashrc && chmod 644 "${MOUNT}"/home/almalinux/.bashrc
  cp -p ${FLAVOR_ROOT}/lcpu "${MOUNT}"/usr/local/bin/ && chmod 755 "${MOUNT}"/usr/local/bin/lcpu
  chown -R 1000:1000 "${MOUNT}"/home/almalinux
  
  cp ${ORIG_PWD}/assets/eda/*.rpm "${MOUNT}"/home/almalinux/
  cp -a ${ORIG_PWD}/assets/eda/opt "${MOUNT}"/

  arch-chroot "${MOUNT}" dnf -y install epel-release
  sed -e 's|^metalink=|#metalink=|g' \
       -e 's|^#baseurl=https\?://download.fedoraproject.org/pub/epel/|baseurl=https://mirrors.pku.edu.cn/epel/|g' \
       -e 's|^#baseurl=https\?://download.example/pub/epel/|baseurl=https://mirrors.pku.edu.cn/epel/|g' \
       -i.bak \
       "${MOUNT}"/etc/yum.repos.d/epel.repo
  cat "${MOUNT}"/etc/yum.repos.d/epel.repo
  arch-chroot "${MOUNT}" dnf -y config-manager --set-enabled powertools
  arch-chroot "${MOUNT}" dnf -y group install "Development Tools" "Server with GUI"
  arch-chroot "${MOUNT}" dnf -y install /home/almalinux/shadowdesk-backend-0.1-1.el8.x86_64.rpm /home/almalinux/shadowdesk-dependencies-1.24-1.el8.x86_64.rpm
  rm "${MOUNT}"/home/almalinux/*.rpm

  # disable selinux
  sed -i 's/^SELINUX=.*/SELINUX=disabled/' "${MOUNT}"/etc/selinux/config
}

function post() {
  # Convert raw image to qcow2 format
  qemu-img convert -c -f qcow2 -O qcow2 "${1}" "${2}"
  rm "${1}"
}