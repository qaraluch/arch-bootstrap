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

readonly tempDir='/tmp/qalacs'
readonly localAppListName='qalacs-app-list.csv'

# Calculated vars
readonly appListDownloadPath="${tempDir}/${localAppListName}"

# Main
main() {
  local cmd
  welcomeMsg
  _isStringEmpty "$_pArgs" && printCommandsUsage
  parseCommand "$_pArgs"
  if _isStringEqual "$cmd" "download" ; then
    execCmd_downloadAppList
    _echoDone
  elif _isStringEqual "$cmd" "show" ; then
    execCmd_showAppList
    _echoDone
  elif _isStringEqual "$cmd" "run" ; then
    execCmd_run
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
        run)
        cmd="$command"
        shift
        break
        ;;
        show)
        cmd="$command"
        shift
        break
        ;;
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

# Command download:
execCmd_downloadAppList() {
  _echoIt "$_pDel" "About to download app list..."
  local source="${p_app_list}"
  local destination="${appListDownloadPath}"
  createTempDir
  curlFile
}

createTempDir() {
  _isDir "${tempDir}" || mkdir "${tempDir}"
  [[ $? ]] && _echoIt "${_pDel}" "  ... created temporary dir for download: "${tempDir}""
}

curlFile() {
  curl -sL "${source}" > "${destination}"
  [[ $? ]] && _echoIt "${_pDel}" "Download of the file: ${_cy}"${destination##*/}${_ce}" completed!" "$_it"
}

# Command show:
execCmd_showAppList() {
  _echoIt "$_pDel" "List of apps that will be installed:"
  local appListYesOnly="$(getAppListYesOnly)"
  showAppList
}

getAppListYesOnly() {
  echo "$(cat "${appListDownloadPath}" | sed -n '/^Y,/p')"
}

showAppList() {
  echo "${appListYesOnly}" \
  | sed -e "1d" \
  | awk -F "\"*,\"*" '{printf " - \033[1;33m%-35s\033[0m - %s\n",$3,$4}'
}

# Command run:
execCmd_run() {
  updateSystem
  installApps
  updateSystem
  addRootPassword
  addUser
}

# Update system
updateSystem() {
  _echoIt "${_pDel}" "About to update the system..."
  pacman -Syu --noconfirm
}

# Install apps
installApps() {
  _echoIt "${_pDel}" "About to install apps..."
  local appListYesOnly="$(getAppListYesOnly)"
  showAppList
  _yesConfirmOrAbort "Continue or abort and edit installation list"
  readAndInstallAppList
  cd "${tempDir}"
  _echoIt "${_pDel}" "${_cg}Installed all apps!${_ce}" "${_it}"
}

readAndInstallAppList() {
  while IFS=, read -r switch repo name purpose ; do
    n=$((n+1)) # omit title row
    case "$repo" in
      "d") install_default "$name" ;;
      "g") install_gitAndMake "$name" ;;
      "a") install_AUR "$name" ;;
    esac
  [[ $? ]] && _echoIt "${_pDel}" "Installed app: ${_cg}"${name}"${_ce}" "${_it}"
  done <<< "${appListYesOnly}"
}

install_default() {
  local name="$1"
	pacman --noconfirm --needed -S "$1"
}

install_gitAndMake() {
  local name="$1"
  local dir=$(mktemp -d)
	git clone --depth 1 "https://github.com/${name}" "$dir"
	cd "$dir" || exit
	make
	make install
	cd /tmp || return
}

#TODO: implement AUR install
# install_AUR() { \
#   echo "$aurinstalled" | grep "^$1$" >/dev/null 2>&1 && return
#   sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
# }

# Add user
# TODO: if works add to tips
# [Recursive function in bash - Stack Overflow](https://stackoverflow.com/questions/9682524/recursive-function-in-bash)
addRootPassword() {
  _echoIt "${_pDel}" "Add root password"
  inputPassAndCheck
  setupRootPass
}

setupRootPass() {
	echo "root:$passwd1" | chpasswd
	unset passwd1 passwd2
  _echoIt "${_pDel}" "Root password set up" "${_it}"
}

addUser() {
  _echoIt "${_pDel}" "It's time to add new user..."
  userName=$(_readUserInput 'Enter user name')
  inputPassAndCheck
  setupUser
}

inputPassAndCheck() {
  typeInPass
  while ! _isStringEqual "${passwd1}" "${passwd2}" ; do
    _echoIt "${_pDel}" "Passwords do not match..." "${_iw}"
    inputPassAndCheck
  done
}

typeInPass() {
  passwd1=$(_readUserInputSilent 'Enter password')
  passwd2=$(_readUserInputSilent 'Retype password')
}

setupUser() {
  groupadd "${userName}"
	useradd -m -g "${userName}" -s /bin/zsh "$userName" >/dev/null 2>&1
	echo "$userName:$passwd1" | chpasswd
	unset passwd1 passwd2
  _echoIt "${_pDel}" "User: ${_cy}${userName}${_ce} set up." "${_it}"
}

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

_readUserInput() {
  local msg=${1:-'Enter here'}
  read -r -p "${_pDel}${_ia} ${msg} ${_cb}>${_ce} "
  echo >&2
  echo ${REPLY}
}

_readUserInputSilent() {
  local msg=${1:-'Enter here'}
  read -r -s -p "${_pDel}${_ia} ${msg} ${_cb}>${_ce} "
  echo >&2
  echo ${REPLY}
}

# Main run!
main