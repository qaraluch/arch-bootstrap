![arch-bootstrap-logo](./pic/logo.jpg)

# arch-bootstrap

> Set of bash scripts for bootstrapping Arch Linux.

- CALIS - Custom Arch Linux Installation Script
- QALACS - Qaraluch's Arch Linux Auto Config Script

Installation of user's dotfiles is not within scope of above scripts anymore.

For installation Arch Linux on WSL2 see [instruction](./wsl2/installation-on-wsl2.md).

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

Before run it edit variables in it in order to setup important information. :warning: **DO RUN THIS WITH EXTRA CAUTION** because is it reformatting `/dev/sda` device.

### Chroot

Script `calis-chroot.sh` performs following tasks in newly created Arch Linux system:

- set up locale to US
- configure timezone to Warsaw one
- set up polish keyboard
- installs systemd-boot bootloader
- installs NetworkManager

There is possibility to reedit script file by aborting script and run it again by:

```
bash /mnt/chroot.sh
```

### Calis installation

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
chmod +x ./calis.sh
./calis.sh
```

then follow the on-screen instructions to completion.
That's it.

For more info read the source code :page_facing_up:.

## 2. QALACS

Next scripts is Qaraluch's Arch Linux Auto Config Script (QALACS) witch set up a functional Arch Linux environment:

- create user
- install basic linux applications from app list
- install AUR helper

### Qalacs installation

After Calis script installation create temp dir:

```
mkdir /tmp/qalacs
cd /tmp/qalacs
```

And download the script:

```
curl -LO https://git.io/qalacs.sh
```

or

```
curl https://raw.githubusercontent.com/qaraluch/arch-bootstrap/master/qalacs.sh -Lo qalacs.sh
```

Launch the script with:

```
chmod +x qalacs.sh
./qalacs.sh download      # download app list
./qalacs.sh show	        # show app list
./qalacs.sh run           # run script
```

then follow the on-screen instructions to completion.
That's it.

For more info read the source code :page_facing_up:.

## Credists

Many thanks to LukeSmithxyz for inspirations.

## License

MIT © [qaraluch](https://github.com/qaraluch)
