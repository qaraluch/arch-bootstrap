![arch-bootstrap-logo](../pic/logo.jpg)

# Installation on WSL2

> Set of scripts for bootstrapping Arch Linux on WSL2.

:warning: Disclaimer:

This code is published in good faith and for learning purpose only. The code is not fully tested, so any usage of it is strictly at your own risk :see_no_evil:.

# Installation of Arch distro on Windows 10

- download distro from: [yuk7/ArchWSL2](https://github.com/yuk7/ArchWSL2)
- unzip it to dir `C:\arch2`
- rename `Arch2.exe` to the `arch2.exe`
- run program `C:\arch2\arch2.exe`

# Setup

- open shell again initialize keyring for pacman:

```
pacman-key --init
pacman-key --populate
```

- update system:

```
pacman -Syu
```

:warning: If you get network error, you may need add firewall rules to allow connections to WSL subnet!

- run QALACS script; see [here](../README.md).

- setup default user for Arch WSL2 distro

in PowerShell:

```
PS C:\arch2> .\arch2.exe config --default-user <username>
```

To continue download and install qdots.

## TODOs:

- [ ] add PS1 script for setup WSL on clean W10 machine; turn on WSL feature; install WSL2 kernel and so on...
