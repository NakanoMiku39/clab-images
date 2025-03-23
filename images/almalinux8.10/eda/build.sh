#!/bin/bash
# shellcheck disable=SC2034,SC2154

# Image configuration
IMAGE_NAME="almalinux8.10-eda-${build_version}.qcow2"
BASE_IMAGE=$(ls -t ${ORIG_PWD}/output/almalinux8.10-pku-*.qcow2 | head -n 1)
DISK_SIZE="150G"
PACKAGES=(redhat-lsb-core libXScrnSaver libnsl libpng12 boost-locale tmux libgfortran ksh java-21-openjdk mesa-libGLU tcsh motif xterm glibc.i686)
SERVICES=(lmg.service)

function pre() {
  mkdir -p "${MOUNT}"/home/almalinux/.config/shadowdesk
  install -m 644 ${FLAVOR_ROOT}/rpmfusion.repo "${MOUNT}"/etc/yum.repos.d/
  cp -p ${FLAVOR_ROOT}/backend.env "${MOUNT}"/home/almalinux/.config/shadowdesk/ && chmod 644 "${MOUNT}"/home/almalinux/.config/shadowdesk/backend.env
  chown -R 1000:1000 "${MOUNT}"/home/almalinux/.config
  install -m 644 ${FLAVOR_ROOT}/*.service "${MOUNT}"/etc/systemd/system/
  cp -p ${FLAVOR_ROOT}/.bashrc "${MOUNT}"/home/almalinux/ && chown 1000:1000 "${MOUNT}"/home/almalinux/.bashrc && chmod 644 "${MOUNT}"/home/almalinux/.bashrc
  install -m 755 ${FLAVOR_ROOT}/lcpu "${MOUNT}"/usr/local/bin/
  chown -R 1000:1000 "${MOUNT}"/home/almalinux
  
  cp ${ORIG_PWD}/assets/eda/*.rpm "${MOUNT}"/home/almalinux/
  cp -a ${ORIG_PWD}/assets/eda/opt "${MOUNT}"/
  chmod 644 "${MOUNT}"/opt/eda/Synopsys/scl/2021.03/admin/license/Synopsys.dat

  echo "* hard nofile 4096" >> "${MOUNT}"/etc/security/limits.conf
  echo "* soft nofile 4096" >> "${MOUNT}"/etc/security/limits.conf

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
  rm "${MOUNT}"/etc/yum.repos.d/{rpmfusion-free-updates-testing.repo,rpmfusion-nonfree-updates.repo,rpmfusion-nonfree-updates-testing.repo,rpmfusion-free-updates.repo}
}


function post() {
  # Convert raw image to qcow2 format
  qemu-img convert -c -f qcow2 -O qcow2 "${1}" "${2}"
  rm "${1}"
}