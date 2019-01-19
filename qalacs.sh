#!/usr/bin/env bash
# Author: qaraluch - 01.2019 - MIT
# Part of the repo: arch-bootstrap
# Qaraluch's Arch Linux Auto Config Script (QALACS)
# Many thanks to LukeSmithxyz for inspiration!

set -e
readonly _pArgs="$@"
readonly _pName=$(basename $0)

########################## INSTALLATION PARAMS ##############################################################
# edit it before run!
readonly p_app_list='https://raw.githubusercontent.com/qaraluch/arch-bootstrap/master/qalacs-app-list.csv'
readonly p_exec_part_XXX='Y'
#############################################################################################################

# Main
main() {
  local cmd
  welcomeMsg
  _isStringEmpty "$_pArgs" && printCommandsUsage
  parseCommand "$_pArgs"
  if _isStringEqual "$cmd" "download" ; then
    execCmd_downloadAppList
    _echoDone
  elif _isStringEqual "$cmd" "run" ; then
    echo run setup
    _echoDone
  fi
  # _switchYN $p_exec_down_chroot && execDownloadChroot
  # _switchYN $p_exec_down_chroot || _echoIt "${_pDel}" "Skipped downloading of chroot script" "$_ic"

  # _switchYN $p_exec_chroot && execChrootWelcomeMsg
  # _switchYN $p_exec_chroot && execChroot
  # _switchYN $p_exec_chroot || _echoIt "${_pDel}" "Skipped run of chroot script" "$_ic"

  # _echoIt "${_pDel}" "ALL DONE!" "$_it"
  # execReboot
}

# CLI
parseCommand() {
    while [[ $# -gt 0 ]]
    do
    command="$1"
    case $command in
        download)
        cmd="$command"
        shift
        break
        ;;
        run)
        cmd="$command"
        shift
        break
        ;;
        *)
        shift
        _echoIt "$_pDel" "Nothing to do ... :("
        exit 1
        ;;
    esac
    done
}

# Msgs:
welcomeMsg() {
  _echoIt
  _echoIt "${_pDel}" "Welcome to: ${_cy}Qaraluch's Arch Linux Auto Config Script${_ce} (QALACS)"
  _echoIt "${_pDel}" "Used variables:"
  _echoIt "${_pDel}" "  - app list to download:        $p_app_list"
  _echoIt "${_pDel}" "Execution subscript flags:"
  _echoIt "${_pDel}" "  - run XXX    [Y]es/[N]o:       $p_exec_part_XXX"
  _echoIt "${_pDel}" "Check above installation settings." "$_iw"
}

printCommandsUsage() {
  _echoIt "${_pDel}" "Re-run this script with passed command argument to perform tasks:" "$_iw"
  cat <<EOL

Usage:
  ${_pName} ${_cy}download${_ce}  - download app list from external source.

  ${_pName} ${_cy}run${_ce}       - run setup script.

  ${_pName} ${_cy}show${_ce}      - show app list that will be installed.

EOL
}

# Calculated vars
# readonly device_full="/dev/${p_device}"

# Command download:
execCmd_downloadAppList() {
  _echoIt "$_pDel" "About to download app list..."
  local tmpDir='/tmp/qalacs'
  local source="${p_app_list}"
  local destination="${tmpDir}/qalacs-app-list.csv"
  createTempDir
  curlFile
}

createTempDir() {
  _isDir "${tmpDir}" || mkdir "${tmpDir}"
  [[ $? ]] && _echoIt "${_pDel}" "  ... created temporary dir for download: "${tmpDir}""
}

curlFile() {
  curl -sL "${source}" > "${destination}"
  [[ $? ]] && _echoIt "${_pDel}" "Download of the file: ${_cy}"${destination##*/}${_ce}" completed!" "$_it"
}

# #------
# execPartitionMgmt() {
#   updateSystemClock
#   _yesConfirmOrAbort
#   _pressAnyKey
#   _echoIt "${_pDel}" "Partitions are set up."
# }

# Utils
readonly _pDel='[ QALACS ]'

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

_echoDone() {
  _echoIt "$_pDel" "DONE!" "$_it"
  echo >&2
}

_isStringEmpty() {
  local var=$1
  [[ -z $var ]]
}

_isStringEqual(){
  [[ "$1" == "$2" ]]
}

_isDir() {
  local dir=$1
  [[ -d $dir ]]
}

# Main run!
main