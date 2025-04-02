# CLab Images

This repository contains images for PKU CLab.

## Dependencies

- `virt-customize`

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

## To-dos

- [ ] Checksum and GPG Verify downloaded images
- [ ] GitHub Actions
- [ ] Global pre/post_commands