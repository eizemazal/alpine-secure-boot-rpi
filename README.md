# Alpine Linux secure boot on Raspberry PI #

I did not find anyone who posted how to pack Alpine Linux into boot.img file for Raspberry Pi. This is needed to enable secure boot on RPi Compute Module 4.

Probably this should be addressed by Alpine maintainers because I did not manage to use Alpine in secure boot without patching init script inside initial ramdisk.

### How it works ### 

We are even speaking of two ramdisks, one is called "initial ramdisk", and its content is inside boot/initramfs-rpi. This is loaded along with the kernel.

The other one is actually created earlier from boot.img by RPi firmware, so let us call it say "primordial ramdisk".The official Linux distro of Raspberry mounts it as /dev/ram0, but in case of Alpine this does not work, I did not find any way to mount it. Maybe another kernel driver is needed for it. Alpine's nlplug-findfs program that tries to find the boot medium, thus fails. So I had to do a workaround by patching init script to mount the SD card first, and then to create a mounted filesystem out of boot.img (the idea behind this is here: https://gitlab.alpinelinux.org/alpine/mkinitfs/-/issues/44). To be honest, this does not look pretty, but I do not know how to do it another way.

Run as `sudo ./build.sh`, because it needs root rights to create loop device an mount image.

The code in build.sh will download Alpine 3.20, unpack initial ramdisk, patch it, and pack it back. Then it will put it along with `bootcode.bin` and config file enabling `boot.img` into `dist/bootable`. Then you have to format eMMC with the first partition as FAT32, mount it, and copy everything from `dist/bootable`.

You will need to sign the boot.img with your private certificate as described in RPi manual in order to enable secure booting.

## CI/CD integration and more ##

I automated creation of Raspberry Pi images inside Gitlab CI/CD pipelines for applications that require cryptographic protection of the software on RPi. The solution, called bake-a-pi, has the following features:

- Based on lightweight Alpine distribution with rootfs residing entirely in RAM (diskless mode). Secure boot of Alpine is supported.
- Builds two types of artifacts: 1. flash/eMMC images that are ready for burning using dd, Balena Etcher etc., and 2. update images digitally signed with custom certificate. Build process is launched locally by single shell command, or can be integrated in CI/CD pipeline. 100% automatic on Linux machine.
- Customizable partitioning with default cryptographic protection of ext4 filesystems via LUKS. Cryptographic protection makes use of Raspberry PI OTP memory which is very hard to break when used together with secure boot. This allows to use interpreted languages like Python or Javascript (Node.js) for the development of business logic on RPi.
- Customizable list of software .apks to be installed at build time to produce a fully functional target system without demand for Internet access. Any custom software like web frontends and Python/Node backends can be deployed to the target image during the build time in CI/CD.
- By default, contains bundled Python with customizable list of requirements that will end up pre-installed on the target
- Bundled persistent network configuration that is stored in yaml, and applied on startup by netconfig script
- Configurable ssh access to the target with your certificates installed during build process
- Failproof automated digitally signed updates using two copies of encrypted filesystem. Your code can just put the update image (generated during CI/CD) to some specified place on the filesystem, and it will be installed during reboot.

If you are interested to license this product, please contact me.