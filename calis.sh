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
  _switchYN $p_exec_part_mgmt || __echoIt "${_pDel}" "${_pDel}" "Skipped set up of partitions" "$_ic"

  _switchYN $p_exec_install_arch && execInstallArch
  _switchYN $p_exec_install_arch || __echoIt "${_pDel}" "${_pDel}" "Skipped installation of Arch Linux" "$_ic"

  _switchYN $p_exec_down_chroot && execDownloadChroot
  _switchYN $p_exec_down_chroot || __echoIt "${_pDel}" "${_pDel}" "Skipped downloading of chroot script" "$_ic"

  _switchYN $p_exec_chroot && execChrootWelcomeMsg
  _switchYN $p_exec_chroot && execChroot
  _switchYN $p_exec_chroot || __echoIt "${_pDel}" "${_pDel}" "Skipped run of chroot script" "$_ic"

  __echoIt "${_pDel}" "${_pDel}" "ALL DONE!" "$_it"
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
  __echoIt "${_pDel}" "${_pDel}" "Welcome to: Custom Arch Linux Installation Script (CALIS)"
  __echoIt "${_pDel}" "${_pDel}" "Used variables:"
  __echoIt "${_pDel}" "${_pDel}" "  - hostname:       $p_hostname"
  __echoIt "${_pDel}" "${_pDel}" "  - device:         $p_device"
  __echoIt "${_pDel}" "${_pDel}" "    - 1. BOOT (MB): $p_part_boot_size"
  __echoIt "${_pDel}" "${_pDel}" "    - 2. SWAP (MB): $p_part_swap_size"
  __echoIt "${_pDel}" "${_pDel}" "    - 3. ROOT (MB): $p_part_root_size"
  __echoIt "${_pDel}" "${_pDel}" "    - 4. HOME (MB): <the rest of the disk size>"
  __echoIt "${_pDel}" "${_pDel}" "  - chroot source:  $p_chroot_source"
  __echoIt "${_pDel}" "${_pDel}" "Execution subscript flags:"
  __echoIt "${_pDel}" "${_pDel}" "  - run partition management    [Y]es/[N]o: $p_exec_part_mgmt"
  __echoIt "${_pDel}" "${_pDel}" "  - run arch installation       [Y]es/[N]o: $p_exec_install_arch"
  __echoIt "${_pDel}" "${_pDel}" "  - download chroot script      [Y]es/[N]o: $p_exec_down_chroot"
  __echoIt "${_pDel}" "${_pDel}" "  - run chroot script           [Y]es/[N]o: $p_exec_chroot"
  __echoIt "${_pDel}" "${_pDel}" "Check above installation settings." "$_iw"
  _yesConfirmOrAbort "Ready to roll"
}

execPartitionMgmt() {
  updateSystemClock
  createPartitions
  showPartitionLayout
  _yesConfirmOrAbort
  formatPartitionsAndMount
  __echoIt "${_pDel}" "${_pDel}" "Partitions are set up."
}

updateSystemClock() {
  timedatectl set-ntp true
  __echoIt "${_pDel}" "${_pDel}" "Updated system clock." "$_it"
}

createPartitions() {
  __echoIt "${_pDel}" "${_pDel}" "About to create partitions..."
  parted --script "${device_full}" -- mklabel msdos \
    mkpart primary ext4 1Mib "${p_part_boot_size}MiB" \
    set 1 boot on \
    mkpart primary linux-swap "${p_part_boot_size}MiB" "${part_swap_size_relative}MiB" \
    mkpart primary ext4 "${part_swap_size_relative}MiB" "${part_root_size_relative}MiB" \
    mkpart primary ext4 "${part_root_size_relative}MiB" 100%
}

showPartitionLayout() {
  parted --script "${device_full}" -- print
  __echoIt "${_pDel}" "${_pDel}" "Created partitions." "$_it"
}

formatPartitionsAndMount() {
  __echoIt "${_pDel}" "${_pDel}" "About to wipe data..."
  wipefs "${part_boot}"
  wipefs "${part_swap}"
  wipefs "${part_root}"
  wipefs "${part_home}"
  __echoIt "${_pDel}" "${_pDel}" "About to format partitions..."
  mkfs.ext4 ${part_boot}
  mkfs.ext4 ${part_root}
  mkfs.ext4 ${part_home}
  mkswap ${part_swap}
  __echoIt "${_pDel}" "${_pDel}" "Formated partitions." "$_it"
  swapon ${part_swap}
  mount ${part_root} /mnt
  mkdir -p /mnt/boot
  mount ${part_boot} /mnt/boot
  mkdir -p /mnt/home
  mount ${part_home} /mnt/home
  __echoIt "${_pDel}" "${_pDel}" "Mounted partitions." "$_it"
}

execInstallArch() {
  __echoIt "${_pDel}" "${_pDel}" "About to install Arch Linux."
  _pressAnyKey
  installArch
  generateFstabFile
  setupHostName
}

installArch() {
  pacstrap /mnt base base-devel
  __echoIt "${_pDel}" "${_pDel}" "Installed Arch." "$_it"
}

generateFstabFile() {
  genfstab -U /mnt >> /mnt/etc/fstab
  __echoIt "${_pDel}" "${_pDel}" "Generated fstab file." "$_it"
  __echoIt "${_pDel}" "${_pDel}" "See fstab file:"
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
  __echoIt "${_pDel}" "${_pDel}" "Setup hostname." "$_it"
}

execDownloadChroot() {
  __echoIt "${_pDel}" "${_pDel}" "About to download calis-chroot.sh script..."
  downloadChrootScript
}

downloadChrootScript() {
  curl -sL "${p_chroot_source}" > /mnt/chroot.sh
  __echoIt "${_pDel}" "${_pDel}" "Download completed!" "$_it"
}

execChrootWelcomeMsg() {
  __echoIt "${_pDel}" "${_pDel}" "Chroot script is downloaded." "$_it"
  __echoIt "${_pDel}" "${_pDel}" "If you need edit some of this settings:"
  __echoIt "${_pDel}" "${_pDel}" "  - locale"
  __echoIt "${_pDel}" "${_pDel}" "  - timezone"
  __echoIt "${_pDel}" "${_pDel}" "  - keyboard"
  __echoIt "${_pDel}" "${_pDel}" "  - bootloader"
  __echoIt "${_pDel}" "${_pDel}" "  - network manager"
  __echoIt "${_pDel}" "${_pDel}" "Abort this script and edit file /mnt/chroot.sh"
  __echoIt "${_pDel}" "${_pDel}" "Re-run only execution of chroot of CALIS script afterwords."
  _yesConfirmOrAbort "Ready to roll"
}

execChroot() {
  __echoIt "${_pDel}" "${_pDel}" "Run arch-chroot..."
  runChroot
}

runChroot() {
  arch-chroot /mnt bash chroot.sh ${device_full} && rm /mnt/chroot.sh
  __echoIt "${_pDel}" "${_pDel}" "Chroot script ended. Clean it up too." "$_it"
}

execReboot() {
  __echoIt "${_pDel}" "${_pDel}" "We are ready to reboot to brand new Arch Linux System..."
  __echoIt "${_pDel}" "${_pDel}" "Fingers crossed!"
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
  __echoIt "${_pDel}" "${_pDel}" "Nothing more to do... :("
}

# Utils
readonly _pDel='[ CALIS ]'

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