#!/usr/bin/env bash
# Author: qaraluch - 08.2018 - MIT
# Part of the repo: arch-bootstrap
# Custom Arch Linux Installation Script (CALIS)
# Many thanks to LukeSmithXYZ for inspiration!

set -e

########################## INSTALLATION PARAMS ##############################################################
# edit it before run!
readonly p_hostname='arch-XXX'
readonly p_device='sda'
readonly p_part_boot_size='250'
readonly p_part_swap_size='2000'
readonly p_part_root_size='10000'
readonly p_chroot_source='https://raw.githubusercontent.com/qaraluch/arch-bootstrap/master/calis-chroot.sh'
readonly p_exec_part_mgmt='Y'
readonly p_exec_install_arch='Y'
readonly p_exec_down_chroot='Y'
readonly p_exec_chroot='Y'
#############################################################################################################

# Main
main() {
  welcomeMsg

  _switchYN $p_exec_part_mgmt && execPartitionMgmt
  _switchYN $p_exec_part_mgmt || _echoIt "${_pDel}" "Skipped set up of partitions" "$_ic"

  _switchYN $p_exec_install_arch && execInstallArch
  _switchYN $p_exec_install_arch || _echoIt "${_pDel}" "Skipped installation of Arch Linux" "$_ic"

  _switchYN $p_exec_down_chroot && execDownloadChroot
  _switchYN $p_exec_down_chroot || _echoIt "${_pDel}" "Skipped downloading of chroot script" "$_ic"

  _switchYN $p_exec_chroot && execChrootWelcomeMsg
  _switchYN $p_exec_chroot && execChroot
  _switchYN $p_exec_chroot || _echoIt "${_pDel}" "Skipped run of chroot script" "$_ic"

  _echoIt "${_pDel}" "ALL DONE!" "$_it"
  execReboot
}

# Calculated vars
readonly device_full="/dev/${p_device}"
readonly part_swap_size_relative=$(( $p_part_swap_size + $p_part_boot_size))
readonly part_root_size_relative=$(( $p_part_root_size + $part_swap_size_relative))
readonly part_boot="${device_full}1"
readonly part_swap="${device_full}2"
readonly part_root="${device_full}3"
readonly part_home="${device_full}4"

welcomeMsg() {
  _echoIt "${_pDel}" "Welcome to: Custom Arch Linux Installation Script (CALIS)"
  _echoIt "${_pDel}" "Used variables:"
  _echoIt "${_pDel}" "  - hostname:       $p_hostname"
  _echoIt "${_pDel}" "  - device:         $p_device"
  _echoIt "${_pDel}" "    - 1. BOOT (MB): $p_part_boot_size"
  _echoIt "${_pDel}" "    - 2. SWAP (MB): $p_part_swap_size"
  _echoIt "${_pDel}" "    - 3. ROOT (MB): $p_part_root_size"
  _echoIt "${_pDel}" "    - 4. HOME (MB): <the rest of the disk size>"
  _echoIt "${_pDel}" "  - chroot source:  $p_chroot_source"
  _echoIt "${_pDel}" "Execution subscript flags:"
  _echoIt "${_pDel}" "  - run partition management    [Y]es/[N]o: $p_exec_part_mgmt"
  _echoIt "${_pDel}" "  - run arch installation       [Y]es/[N]o: $p_exec_install_arch"
  _echoIt "${_pDel}" "  - download chroot script      [Y]es/[N]o: $p_exec_down_chroot"
  _echoIt "${_pDel}" "  - run chroot script           [Y]es/[N]o: $p_exec_chroot"
  _echoIt "${_pDel}" "Check above installation settings." "$_iw"
  _yesConfirmOrAbort "Ready to roll"
}

execPartitionMgmt() {
  updateSystemClock
  createPartitions
  showPartitionLayout
  _yesConfirmOrAbort
  formatPartitionsAndMount
  _echoIt "${_pDel}" "Partitions are set up."
}

updateSystemClock() {
  timedatectl set-ntp true
  _echoIt "${_pDel}" "Updated system clock." "$_it"
}

createPartitions() {
  _echoIt "${_pDel}" "About to create partitions..."
  parted --script "${device_full}" -- mklabel msdos \
    mkpart primary ext4 1Mib "${p_part_boot_size}MiB" \
    set 1 boot on \
    mkpart primary linux-swap "${p_part_boot_size}MiB" "${part_swap_size_relative}MiB" \
    mkpart primary ext4 "${part_swap_size_relative}MiB" "${part_root_size_relative}MiB" \
    mkpart primary ext4 "${part_root_size_relative}MiB" 100%
}

showPartitionLayout() {
  parted --script "${device_full}" -- print
  _echoIt "${_pDel}" "Created partitions." "$_it"
}

formatPartitionsAndMount() {
  _echoIt "${_pDel}" "About to wipe data..."
  wipefs "${part_boot}"
  wipefs "${part_swap}"
  wipefs "${part_root}"
  wipefs "${part_home}"
  _echoIt "${_pDel}" "About to format partitions..."
  mkfs.ext4 ${part_boot}
  mkfs.ext4 ${part_root}
  mkfs.ext4 ${part_home}
  mkswap ${part_swap}
  _echoIt "${_pDel}" "Formated partitions." "$_it"
  swapon ${part_swap}
  mount ${part_root} /mnt
  mkdir -p /mnt/boot
  mount ${part_boot} /mnt/boot
  mkdir -p /mnt/home
  mount ${part_home} /mnt/home
  _echoIt "${_pDel}" "Mounted partitions." "$_it"
}

execInstallArch() {
  _echoIt "${_pDel}" "About to install Arch Linux."
  _pressAnyKey
  installArch
  generateFstabFile
  setupHostName
}

installArch() {
  pacstrap /mnt base base-devel
  _echoIt "${_pDel}" "Installed Arch." "$_it"
}

generateFstabFile() {
  genfstab -U /mnt >> /mnt/etc/fstab
  _echoIt "${_pDel}" "Generated fstab file." "$_it"
  _echoIt "${_pDel}" "See fstab file:"
  more /mnt/etc/fstab
}

setupHostName() {
  echo $p_hostname > /mnt/etc/hostname
  cat <<EOT >> /mnt/etc/hosts
127.0.0.1	localhost
::1		localhost
# 127.0.1.1	myhostname.localdomain	myhostname
EOT
  # sed -i "8i 127.0.1.1\t$p_hostname.localdomain\t$p_hostname" /etc/hosts
  _echoIt "${_pDel}" "Setup hostname." "$_it"
}

execDownloadChroot() {
  _echoIt "${_pDel}" "About to download calis-chroot.sh script..."
  downloadChrootScript
}

downloadChrootScript() {
  curl -sL "${p_chroot_source}" > /mnt/chroot.sh
  _echoIt "${_pDel}" "Download completed!" "$_it"
}

execChrootWelcomeMsg() {
  _echoIt "${_pDel}" "Chroot script is downloaded." "$_it"
  _echoIt "${_pDel}" "If you need edit some of this settings:"
  _echoIt "${_pDel}" "  - locale"
  _echoIt "${_pDel}" "  - timezone"
  _echoIt "${_pDel}" "  - keyboard"
  _echoIt "${_pDel}" "  - bootloader"
  _echoIt "${_pDel}" "  - network manager"
  _echoIt "${_pDel}" "Abort this script and edit file /mnt/chroot.sh"
  _echoIt "${_pDel}" "Re-run only execution of chroot of CALIS script afterwords."
  _yesConfirmOrAbort "Ready to roll"
}

execChroot() {
  _echoIt "${_pDel}" "Run arch-chroot..."
  runChroot
}

runChroot() {
  arch-chroot /mnt bash chroot.sh ${device_full} && rm /mnt/chroot.sh
  _echoIt "${_pDel}" "Chroot script ended. Clean it up too." "$_it"
}

execReboot() {
  _echoIt "${_pDel}" "We are ready to reboot to brand new Arch Linux System..."
  _echoIt "${_pDel}" "Fingers crossed!"
  rebootNow
  orGoBackToChroot
}

rebootNow() {
  read -p "$D_APP$_ia Confirm reboot or skip it [y/n]?" -n 1 -r
  echo >&2
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    umount -R /mnt
    swapoff ${part_swap}
    shutdown -h now
  fi
}

orGoBackToChroot() {
  read -p "$D_APP$_ia Maybe go to chroot again or skip it [y/n]?" -n 1 -r
  echo >&2
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    arch-chroot /mnt
  fi
  clear
  _echoIt "${_pDel}" "Nothing more to do... :("
}

# Utils
readonly _pDel='[ CALIS ]'

export _cr=$'\033[0;31m'            # color red
export _cg=$'\033[1;32m'            # color green
export _cy=$'\033[1;33m'            # color yellow
export _cb=$'\033[1;34m'            # color blue
export _cm=$'\033[1;35m'            # color magenta
export _cc=$'\033[1;36m'            # color cyan
export _ce=$'\033[0m'               # color end

export _it="[ ${_cg}✔${_ce} ]"        # icon tick
export _iw="[ ${_cy}!${_ce} ]"       # icon warn
export _ic="[ ${_cr}✖${_ce} ]"      # icon cross
export _ia="[ ${_cy}?${_ce} ]"      # icon ask

_echoIt() {
  local delimiter=$1 ; local msg=$2 ; local icon=${3:-''} ; echo "${delimiter}${icon} $msg" >&2
}

_errorExit() {
  local delimiter=$1 ; local msg=$2 ; local icon=${3:-"$_ic"} ; echo "${delimiter}${icon} ${msg}" 1>&2 ; exit 1
}

_yesConfirmOrAbort() {
  local msg=${1:-'Continue'}
  local msgDefaultAbort=${2:-'Abort script!'}
  read -n 1 -s -r -p "${_pDel}${_ia} ${msg} [Y/n]?"
  echo >&2
  REPLY=${REPLY:-'Y'}
  if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    _errorExit "${_pDel}" "${msgDefaultAbort}"
  fi
}

_pressAnyKey() {
  read -n 1 -s -r -p "${_pDel}${_ia} Press [any] key to continue. "
  echo >&2
}

_isStringEqualY() {
  local string=$1
  [[ "$string" == "Y" ]]
}

_switchYN() {
  local switch=$1
  if _isStringEqualY $switch; then
    return 0
  else
    return 1
  fi
}

# Main run!
main