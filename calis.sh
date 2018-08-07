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
}

#TOSCAV:  EOF
createPartitions () {
local PART_LAYOUT=$(cat <<EOF
0,250,L
,2000,S
,10000,L
,,L
EOF 
)
echo ${PART_LAYOUT} | sfdisk "/dev/${DEVICE}" -uM 
}

showPartitionLayout () {
  sfdisk -l "/dev/${DEVICE}"
}

################################### VARS ###################################
readonly HOSTNAME='arch-XXX'  
readonly DEVICE='sda'
readonly PART_BOOT_SIZE='250'
readonly PART_SWAP_SIZE='2000'
readonly PART_ROOT_SIZE='10000'

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

  echoIt "DONE!" "$I_T"
  exit 0
}

main #run it!
