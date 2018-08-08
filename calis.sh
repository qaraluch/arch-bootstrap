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

################################### VARS ###################################
readonly HOSTNAME='arch-XXX'  
readonly DEVICE='sda'
readonly PART_BOOT_SIZE='250'
readonly PART_SWAP_SIZE='2000'
readonly PART_ROOT_SIZE='10000'

readonly DEVICE_FULL="/dev/${DEVICE}"
readonly PART_SWAP_SIZE_RELATIVE=$(( $PART_SWAP_SIZE + $PART_BOOT_SIZE))
readonly PART_ROOT_SIZE_RELATIVE=$(( $PART_ROOT_SIZE + $PART_SWAP_SIZE_RELATIVE))

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
  echoIt "Check above installation settings." "$I_W"
  yesConfirm "Ready to roll [y/n]? " 

  #Setup fns:
    updateSystemClock || errorExitMainScript
    #Parition mgmt
    createPartitions || errorExitMainScript
    showPartitionLayout || errorExitMainScript
    yesConfirm "Continue... [y/n]? " 

  echoIt "DONE!" "$I_T"
  exit 0
}

main #run it!
