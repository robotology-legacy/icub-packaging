#!/bin/bash -e
# build-all-iCub-packages.sh
#set -x
# Defaults
SETTINGS_FILE="config.sh"
BUILD_SCRIPT="build-iCub-packages.sh"
CLEANUP_SCRIPT="clean_icub_builds.sh"
BUILD_PATH="/data"
#
SCRIPT_PATH=$(dirname $0)
CLEANUP="false"

print_defs ()
{
  echo "Default parameters are"
  echo "  SETTINGS_FILE is $SETTINGS_FILE"
  echo "  BUILD_PATH is $BUILD_PATH"
  echo "  BUILD_SCRIPT is $BUILD_SCRIPT"
  echo "  CLEANUP_SCRIPT is $CLEANUP_SCRIPT"
  echo "  SCRIPT_PATH is $SCRIPT_PATH"
}

usage ()
{
  echo "SCRIPT DESCRIPTION"

  echo "Usage: $0 [options]"
  echo "options are :"

  echo "  -D : delete packages instead of build (and clean up the build enviroment)"
  echo "  -d : print defaults"
  echo "  -h : print this help"
}

log() {
  echo "\e[96m$(date +%d-%m-%Y) - $(date +%H:%M:%S) : $1\e[39m"
}

warn() {
  echo "e[33m$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : $1\e[39m"
 }
 
error() {
  echo "\e[31m$(date +%d-%m-%Y) - $(date +%H:%M:%S) ERROR : $1\e[39m"
}

exit_err () {
	error "$1"
	exit 1
}


parse_opt() {
  while getopts hdD opt
  do
    case "$opt" in
    D)
      CLEANUP="true"
      ;;
    h)
      usage
      exit 0
      ;;
    d)
      print_defs
      exit 0
      ;;
    \?) # unknown flag
      usage
      exit 1
      ;;
    esac
  done
}

init()
{
  if [ "$(whoami)" != "root" ]; then
    exit_err "please execute this script as root"
  fi
  if [ ! -f "${SCRIPT_PATH}/${SETTINGS_FILE}" ]; then
    exit_err "configuration file ${SCRIPT_PATH}/${SETTINGS_FILE} not found"
  fi
  source ${SCRIPT_PATH}/${SETTINGS_FILE}
  
  if [ "$CLEANUP" == "true" ]; then
    if [ ! -f "${SCRIPT_PATH}/${CLEANUP_SCRIPT}" ]; then
      exit_err "build script ${SCRIPT_PATH}/${CLEANUP_SCRIPT} not found"
    fi
  else
    if [ ! -f "${SCRIPT_PATH}/${BUILD_SCRIPT}" ]; then
      exit_err "build script ${SCRIPT_PATH}/${BUILD_SCRIPT} not found"
    fi
  fi
  if [ ! -d "${BUILD_PATH}" ]; then
    exit_err "build path ${BUILD_PATH} not available"
  fi
  
  log "Supported distro are $SUPPORTED_DISTRO_LIST"
  log "Supported platforms are $SUPPORTED_TARGET_LIST"
 
  log "$0 STARTED"
}

fini()
{
  log "$0 ENDED "
}

main()
{
  for distro in $SUPPORTED_DISTRO_LIST ; do
    for target in $SUPPORTED_TARGET_LIST ; do 
      if [ "$CLEANUP" == "true" ]; then
        log "Now cleaning for $distro $target"
        ${SCRIPT_PATH}/${CLEANUP_SCRIPT} ${BUILD_PATH} ${distro}_${target}
       
      else
        log "Now building for $distro $target"
        ${SCRIPT_PATH}/${BUILD_SCRIPT} $BUILD_PATH ${distro}_${target}
      fi
    done
  done

}

parse_opt "$@"
init
main
fini
exit 0
