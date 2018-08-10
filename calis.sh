#!/usr/bin/env bash

# Author: qaraluch - 08.2018 - MIT
# Part of project name: arch-bootstrap 
# Custom Arch Linux Installation Script (CALIS)

################################### UTILS ###################################
# DELIMITER
readonly D_APP='[ CALIS ]'

# COLORS
readonly C_R=$'\033[0;31m'            # Red
readonly C_G=$'\033[1;32m'            # Green
readonly C_Y=$'\033[1;33m'            # Yellow
readonly C_B=$'\033[1;34m'            # Blue
readonly C_M=$'\033[1;35m'            # Magenta
readonly C_C=$'\033[1;36m'            # Cyan
readonly C_E=$'\033[0m'               # End

# ICONS
readonly I_T="[ ${C_G}✔${C_E} ]"      # Tick
readonly I_W="[ ${C_Y}!${C_E} ]"      # Warn
readonly I_C="[ ${C_R}✖${C_E} ]"      # Cross
readonly I_A="[ ${C_Y}?${C_E} ]"      # Ask

echoIt () {
  local msg=$1 ; local icon=${2:-''} ; echo "$D_APP$icon $msg" 
}

errorExit () {
  echo "$D_APP$I_C $1" 1>&2 ; exit 1
}

errorExitMainScript () {
  errorExit "${C_R}Sth. went wrong. Aborting script! $C_E"
}

yesConfirm () {
  local ABORT_MSG_DEFAULT="Abort script!"
  local ABORT_MSG=${2:-$ABORT_MSG_DEFAULT}
  read -p "$D_APP$I_A $1" -n 1 -r
  echo >&2
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      errorExit "$ABORT_MSG" 
  fi
}

pressAnyKey () {
  read -n 1 -s -r -p "$D_APP Press [any] key to continue."
  echo >&2
}

isEqualY () {
  local STRING=$1
  [[ "$STRING" == "Y" ]]
}

isEqualN () {
  local STRING=$1
  [[ "$STRING" == "N" ]]
}

switchYN () {
  local SWITCH=$1
  if isEqualY $SWITCH; then
    return 0
  else
    return 1
  fi
} 
################################### FNS  ###################################
updateSystemClock () {
  timedatectl set-ntp true
  echoIt "Updated system clock." "$I_T"
}

createPartitions () {
  echoIt "About to create partitions..." 
  parted --script "${DEVICE_FULL}" -- mklabel gpt \
    mkpart primary ext4 1Mib "${PART_BOOT_SIZE}MiB" \
    mkpart primary linux-swap "${PART_BOOT_SIZE}MiB" "${PART_SWAP_SIZE_RELATIVE}MiB" \
    mkpart primary ext4 "${PART_SWAP_SIZE_RELATIVE}MiB" "${PART_ROOT_SIZE_RELATIVE}MiB" \
    mkpart primary ext4 "${PART_ROOT_SIZE_RELATIVE}MiB" 100%
} 

showPartitionLayout () {
  parted --script "${DEVICE_FULL}" -- print
  echoIt "Created partitions." "$I_T"
}

formatPartitionsAndMount () {
  echoIt "About to wipe data..." 
  wipefs "${PART_BOOT}"
  wipefs "${PART_SWAP}"
  wipefs "${PART_ROOT}"
  wipefs "${PART_HOME}"
  echoIt "About to format partitions..." 
  mkfs.ext4 ${PART_BOOT}
  mkfs.ext4 ${PART_ROOT}
  mkfs.ext4 ${PART_HOME}
  mkswap ${PART_SWAP}
  echoIt "Formated partitions." "$I_T"
  swapon /dev/sda2
  mount ${PART_ROOT} /mnt
  mkdir -p /mnt/boot
  mount ${PART_BOOT} /mnt/boot
  mkdir -p /mnt/home
  mount ${PART_HOME} /mnt/home
  echoIt "Mounted partitions." "$I_T"
}

installArch () {
  pacstrap /mnt base base-devel
  echoIt "Installed Arch." "$I_T"
}

generateFstabFile () {
  genfstab -U /mnt >> /mnt/etc/fstab
  echoIt "Generated fstab file." "$I_T"
  echoIt "See fstab file:" 
  more /mnt/etc/fstab
}

downloadChrootScript () {
  curl -sL "${CHROOT_SOURCE}" > /mnt/chroot.sh
  echoIt "Download completed!" "$I_T"
}

################################### VARS ###################################
readonly HOSTNAME='arch-XXX'  
readonly DEVICE='sda'
readonly PART_BOOT_SIZE='250'
readonly PART_SWAP_SIZE='2000'
readonly PART_ROOT_SIZE='10000'
readonly CHROOT_SOURCE='https://raw.githubusercontent.com/qaraluch/arch-bootstrap/master/calis-chroot.sh'
readonly EXEC_PART_MGMT='Y'
readonly EXEC_INSTALL_ARCH='Y'
readonly EXEC_DOWN_CHROOT='Y'

### Calculated vars:
readonly DEVICE_FULL="/dev/${DEVICE}"
readonly PART_SWAP_SIZE_RELATIVE=$(( $PART_SWAP_SIZE + $PART_BOOT_SIZE))
readonly PART_ROOT_SIZE_RELATIVE=$(( $PART_ROOT_SIZE + $PART_SWAP_SIZE_RELATIVE))
readonly PART_BOOT="${DEVICE_FULL}1"
readonly PART_SWAP="${DEVICE_FULL}2"
readonly PART_ROOT="${DEVICE_FULL}3"
readonly PART_HOME="${DEVICE_FULL}4"

################################### MAIN ###################################
main () {
  echoIt "Welcome to: Custom Arch Linux Installation Script (CALIS)"
  echoIt "Used variables:"
  echoIt "  - hostname:       $HOSTNAME"
  echoIt "  - device:         $DEVICE"
  echoIt "    - 1. BOOT (MB): $PART_BOOT_SIZE"
  echoIt "    - 2. SWAP (MB): $PART_SWAP_SIZE"
  echoIt "    - 3. ROOT (MB): $PART_ROOT_SIZE"
  echoIt "    - 4. HOME (MB): <the rest of the disk size>"
  echoIt "  - chroot source:  $CHROOT_SOURCE"
  echoIt "Execution subscript flags:"
  echoIt "  - run partition management    [Y]es/[N]o: $EXEC_PART_MGMT"
  echoIt "  - run arch installation       [Y]es/[N]o: $EXEC_INSTALL_ARCH"
  echoIt "  - run chroot script download  [Y]es/[N]o: $EXEC_DOWN_CHROOT"
  echoIt "Check above installation settings." "$I_W"
  yesConfirm "Ready to roll [y/n]? " 
}

execPartitionMgmt () {
  updateSystemClock || errorExitMainScript
  createPartitions || errorExitMainScript
  showPartitionLayout || errorExitMainScript
  yesConfirm "Continue... [y/n]? " 
  formatPartitionsAndMount || errorExitMainScript
  echoIt "Partitions are set up."
}

execInstallArch () {
  echoIt "About to install Arch Linux."
  pressAnyKey
  installArch || errorExitMainScript 
  generateFstabFile || errorExitMainScript
}

execDownChroot () {
  echoIt "About to download calis-chroot.sh script..." 
  pressAnyKey
  downloadChrootScript || errorExitMainScript 
  echoIt "Chroot script is downloaded. So I need you to type in the console:"
  echoIt "  # arch-chroot /mnt bash chroot.sh"
}

main #run it!
switchYN $EXEC_PART_MGMT && execPartitionMgmt
switchYN $EXEC_PART_MGMT || echoIt "Skipped set up of partitions" "$I_C"
switchYN $EXEC_INSTALL_ARCH && execInstallArch
switchYN $EXEC_INSTALL_ARCH || echoIt "Skipped installation of Arch Linux" "$I_C"
switchYN $EXEC_DOWN_CHROOT && execDownChroot
switchYN $EXEC_DOWN_CHROOT || echoIt "Skipped downloading of chroot script" "$I_C"
echoIt "DONE!" "$I_T"