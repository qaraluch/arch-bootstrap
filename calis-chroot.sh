#!/usr/bin/env bash
# Author: qaraluch - 08.2018 - MIT
# Part of the repo: arch-bootstrap
# Custom Arch Linux Installation Script (CALIS)
# Chroot part

# Main
main() {
  local devicePath=$1
  _echoIt "${_pDel}" "Welcome to: Custom Arch Linux Installation Script (CALIS - CHROOT)"
  _echoIt "${_pDel}" "Used variables from calis script:"
  _echoIt "${_pDel}" "  - device:       $devicePath"
  _yesConfirmOrAbort "Ready to roll"
  setupLocale
  setupTimeZone
  setupKeyboard
  installBootLoader $devicePath
  installNetworkManager
  _echoIt "${_pDel}" "DONE!" "$_it"
}

setupLocale() {
  echo "LANG=en_US.UTF-8" > /etc/locale.conf
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  echo "en_US ISO-8859-1" >> /etc/locale.gen
  locale-gen
  _echoIt "${_pDel}" "Setup locale." "$_it"
}

setupTimeZone() {
  ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
  hwclock --systohc
  _echoIt "${_pDel}" "Setup timezone and clock." "$_it"
}

setupKeyboard() {
  cat <<EOT >> /etc/vconsole.conf
KEYMAP=pl
FONT=Lat2-Terminus16.psfu.gz
FONT_MAP=8859-2
EOT
  _echoIt "${_pDel}" "Setup keyboard layout." "$_it"
}

installBootLoader() {
  local device=$1
  _echoIt "${_pDel}" "Installing bootloader: GRUB on device: ${device}"
  _pressAnyKey
  pacman --noconfirm --needed -Syu grub \
    && grub-install --target=i386-pc ${device} \
    && grub-mkconfig -o /boot/grub/grub.cfg
  _echoIt "${_pDel}" "Installed bootloader" "$_it"
}

installNetworkManager() {
  pacman --noconfirm --needed -S networkmanager
  systemctl enable NetworkManager
  systemctl start NetworkManager
  _echoIt "${_pDel}" "Installed NetworkManager" "$_it"
}

################################### UTILS ###################################
# DELIMITER
readonly _pDel='[ CALIS-CHROOT ]'

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

# Main run!
main $1
