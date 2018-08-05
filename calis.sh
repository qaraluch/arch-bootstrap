#!/usr/bin/env bash

# Author: qaraluch - 08.2018 - MIT
# Part of project name: arch-bootstrap 
# Custom Arch Linux Installation Script (CALIS)

###
#TODO: 

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
  local msg=$1 ; local icon=${2:-''} ; echo "$D_APP$icon $msg" >&2
}

errorExit () {
  echo "$D_APP$I_C $1" 1>&2 ; exit 1
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

################################### VARS ###################################
readonly HOSTNAME='arch-XXX'  
readonly DEVICE='sda'

################################### MAIN ###################################
main () {
  echoIt "Welcome to: Custom Arch Linux Installation Script (CALIS)"
  echoIt "Used variables:"
  echoIt "  - hostname:   $HOSTNAME"
  echoIt "  - device:     $DEVICE"
  yesConfirm "Ready to roll [y/n]? " 
  echoIt "DONE!" "$I_T"
  exit 0
}

main #run it!
