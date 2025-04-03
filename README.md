# CLab Images

This repository contains images for PKU CLab.

## Dependencies

- `virt-customize`
- `virt-resize` (for growing disk images)

## Usage

### Build an Image

```bash
git clone https://github.com/lcpu-club/clab-images.git
cd clab-images
./bin/build-vm <distro> <flavor> [version]
```
### Add a new distro

Setup config and respective scripts in `images/<distro>/distro.conf`, `images/<distro>/{pre,post}_commands`, `images/<distro>/<flavor>/flavor.conf` and `images/<distro>/<flavor>/{pre_post}_commands`.

Paths should be relative to project root.

## Q&A

### `/usr/bin/supermin` exited with error

This error may be due to no permission to access vmlinuz and kernel modules. You could 1. allow current user to access `/boot/vmlinuz` and `/lib/modules/<version>`; 2. download linux kernel and modules to local folder.

To download kernel and kernel modules:
```bash
# e.g. extract required files from ubuntu mainline kernels
wget https://kernel.ubuntu.com/mainline/v6.14/amd64/linux-image-unsigned-6.14.0-061400-generic_6.14.0-061400.202503241442_amd64.deb
dpkg-deb -R linux-image-unsigned-6.14.0-061400-generic_6.14.0-061400.202503241442_amd64.deb kernel
wget https://kernel.ubuntu.com/mainline/v6.14/amd64/linux-modules-6.14.0-061400-generic_6.14.0-061400.202503241442_amd64.deb
dpkg-deb -R linux-modules-6.14.0-061400-generic_6.14.0-061400.202503241442_amd64.deb kernel/modules
depmod -b kernel/modules 6.14.0-061400-generic
```

Then run `build-vm` with `SUPERMIN_KERNEL=kernel/boot/vmlinuz-6.14.0-061400-generic SUPERMIN_MODULES=kernel/modules/lib/modules/6.14.0-061400-generic/ ./build-vm almalinux8.10 eda`

### Can't resolve hostname inside virt-customize

Under circumstances when the host's `/etc/resolv.conf` specifies dns server at `localhost` or other corner cases, the virt-host 

## To-dos

- [ ] Checksum and GPG Verify downloaded images
- [ ] GitHub Actions
- [ ] Global pre/post_commands