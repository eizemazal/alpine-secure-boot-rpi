#!/bin/sh


ALPINE_VERSION_MAJOR="3.20"
ALPINE_VERSION_MINOR="2"


error() {
    echo $1
    exit 1
}

rm -rf dist/
mkdir -p dist/alpine
cd dist/alpine
wget https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION_MAJOR}/releases/aarch64/alpine-rpi-$ALPINE_VERSION_MAJOR.$ALPINE_VERSION_MINOR-aarch64.tar.gz || error "Unable to download Alpine"
tar xzf "alpine-rpi-$ALPINE_VERSION_MAJOR.$ALPINE_VERSION_MINOR-aarch64.tar.gz" || error "Unable to unpack Alpine tarball"
rm "alpine-rpi-$ALPINE_VERSION_MAJOR.$ALPINE_VERSION_MINOR-aarch64.tar.gz"
mkdir initramfs
cp boot/initramfs-rpi initramfs/
cd initramfs
# uncompress initial ramdisk
zcat initramfs-rpi | cpio -idmv
rm initramfs-rpi
# add patch to remove nlplug-findfs that tries to find boot media
patch init ../../../init.patch || error "Patching did not succeed - maybe init script from Alpine repo has been changed."

# for Alpine version of cpio:
# find . | cpio -o -H newc -R root:root | gzip -9
# for usual Linux:
find . | cpio -o -c -R root:root | gzip -9 > ../initramfs-new
cd ..
rm -rf initramfs 
mv initramfs-new boot/initramfs-rpi
cd ..
dd if=/dev/zero of=boot.img bs=1M count=87 conv=fsync || error "Unable to create boot.img"
mkfs.vfat boot.img || error "Unable to make vfat on boot.img"
mkdir imgmount
mount boot.img imgmount || error "Unable to mount: are you running as root?"
cp -r alpine/* imgmount/
cp imgmount/bootcode.bin .
umount imgmount
rm -rf imgmount
mkdir bootable
mv boot.img bootcode.bin bootable
echo "boot_ramdisk=1" > bootable/config.txt
echo "Done!"