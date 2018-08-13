![arch-bootstrap-logo](./pic/logo.jpg)

# arch-bootstrap

> Set of bash scripts for bootstrapping Arch Linux.

:warning: Disclaimer:

This code is published in good faith and for learning purpose only. The code is not fully tested, so any usage of it is strictly at your own risk :see_no_evil:.

## 1. CALIS

First of scripts is Custom Arch Linux Installation Script (CALIS). Main purpose of it is installation of minimal Arch Linux i.e:

- updates system clock,
- creates partitions,
- format partitions,
- install Arch Linux libs,
- generate fstab,
- setup hostname and creates `/etc/hosts` file,
- download chroot script and run it.

Before run it edit variables in it in order to setup important information. DO RUN THIS WITH EXTRA CAUTION because is it reformatting `/dev/sda` device.

### Chroot

Script `calis-chroot.sh` performs following tasks in newly created Arch Linux system:

- set up locale to US
- configure timezone to Warsaw one
- set up polish keyboard
- installs GRUB bootloader
- installs NetworkManager

There is possibility to reedit script file by aborting script and run it again by:

```
bash /mnt/chroot.sh
```

## Installation

Boot with the Arch Linux image found [here](https://www.archlinux.org/download/).

Download the script with:

```
curl -LO https://git.io/calis.sh
```

or

```
curl https://raw.githubusercontent.com/qaraluch/arch-bootstrap/master/calis.sh -Lo calis.sh
```

And launch the script with:

```
bash calis.sh
```

then follow the on-screen instructions to completion.
That's it.

For more info read the source code :page_facing_up:.

## Credists

Many thanks to LukeSmithXYZ for inspirations.

## License

MIT © [qaraluch](https://github.com/qaraluch)
