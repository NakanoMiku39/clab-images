# CLab Images

This repository contains images for PKU CLab.

## Usage

```bash
# Clone this repository
git clone https://github.com/lcpu-club/clab-images.git
cd clab-images
# build the image
./bin/build-vm <distro> <flavor>
```

## Dependencies

- `qemu-img`
- `qemu-nbd`

## Add a new distro

You should setup some variables and functions in `images/<distro>/common.sh`. You can find an example in `images/ubuntu/common.sh`.

```bash
DISTRO=<distro>
BASE_IMAGE=<base_image>
function download_source(){}
function resize_image(){}
function os_update(){}
function os_install(){}
function os_cleanup(){}
function mount_image(){}
function unmount_image(){}
```

## Add a new flavor

Two functions should be defined in `images/<distro>/<flavor>/build.sh`. You can find an example in `images/ubuntu/pku/build.sh`.

```bash
IMAGE_NAME=<image_name>
DISK_SIZE=<disk_size>
PACKAGES=(<package1> <package2> ...)
SERVICES=(<service1> <service2> ...)
function pre(){}
function post(){}
```

Note, pre will be executed after the installation of packages, and post will be executed before the cleanup.


## Common Troubleshooting

### partition table lost after image creation

`post` function will compress the image and create a new one. You should specify image type correctly. If the source image is `qcow2`, but you specify `raw` in `post`, the partition table will be lost.

### mount point busy

vscode git plugin will scan your working directory and cause the mount point busy. You should close vscode or change the working directory.

### ERROR: failed to setup resolv.conf

In some os images, `/etc/resolv.conf` is a symbolic link, e.g. it is `/run/systemd/resolve/stub-resolv.conf` for ubuntu series. Ensure that you have this file (`/run/systemd/resolve/stub-resolv.conf`) available on your host system or arch-chroot won't be able to mount your host `/etc/resolv.conf`.