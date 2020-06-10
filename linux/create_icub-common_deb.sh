#!/bin/bash -e
#set -x
# #####################################################
# SCRIPT NAME: create_icub-common_deb.sh
#
# DESCRIPTION: this script creates the icub-common
# metapackage
#
# AUTHOR : Matteo Brunettini <matteo.brunettini@iit.it>
#
# LATEST MODIFICATION DATE (YYYY-MM-DD): 2020-06-10
#
SCRIPT_VERSION="0.9"          # Sets version variable
SCRIPT_TEMPLATE_VERSION="1.2.1" #
SCRIPT_NAME=$(realpath -s $0)
SCRIPT_PATH=$(dirname $_SCRIPT)
#
# #####################################################
# COLORS
COL_NORMAL="\e[0m"
COL_ERROR=" \e[31m"
COL_OK="\e[32m"
COL_DONE="\e[96m"
COL_ACTION="\033[1;90m"
COL_WARNING="\e[33m"

# Defaults
LOG_FILE=""
PLATFORM_HARDWARE="amd64" # TODO
PACKAGE_VERSION=""
# Always use a revision number >=1
DEBIAN_REVISION_NUMBER="1"
YCM_PACKAGE="ycm-cmake-modules"
YCM_PACKAGE_URL_bionic="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/${YCM_PACKAGE}_0.11.1-1~ubuntu18.04~robotology1_all.deb"
YCM_PACKAGE_URL_buster="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/${YCM_PACKAGE}_0.11.1-1_all.deb"
YCM_PACKAGE_URL_focal="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/${YCM_PACKAGE}_0.11.1-1_all.deb"
SUPPORTED_DISTRO_LIST="buster bionic focal"
SUPPORTED_TARGET_LIST="amd64"
CMAKE_MIN_REQ_VER="3.12.0"
ICUB_DEPS_COMMON="libace-dev libc6 python libgsl0-dev libncurses5-dev libsdl1.2-dev subversion git gfortran libxmu-dev libode-dev wget unzip qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev libqt5svg5 libqt5opengl5-dev libopencv-dev freeglut3-dev libtinyxml-dev libblas-dev coinor-libipopt-dev liblapack-dev libmumps-dev qml-module-qtmultimedia qml-module-qtquick-dialogs qml-module-qtquick-controls libedit-dev libeigen3-dev libjpeg-dev libsimbody-dev libxml2-dev libjs-underscore ${YCM_PACKAGE}"
ICUB_DEPS_bionic="libode6"
ICUB_DEPS_focal="libode8"
ICUB_DEPS_buster="libode8"
ICUB_REPO_URL="https://github.com/robotology/icub-main"
ICUB_PACKAGE_MAINTAINER="Matteo Brunettini <matteo.brunettini@iit.it>"

# locals
_EQUIVS_BIN=$(which equivs-build)
_PLATFORM_KEY=$(lsb_release -sc)
_CONTROL_FILE="icub-common.${_PLATFORM_KEY}-${PLATFORM_HARDWARE}.control"
# #####################################################

print_defs ()
{
  echo "Default parameters are"
  echo " SCRIPT_TEMPLATE_VERSION is $SCRIPT_TEMPLATE_VERSION"
  echo " SCRIPT_VERSION is $SCRIPT_VERSION"
  if [ "$LOG_FILE" != "" ]
  then
    echo "  log file is $LOG_FILE"
  fi
  echo "Local parameters are"
  echo "  PLATFORM_HARDWARE is $PLATFORM_HARDWARE"
  echo "  PACKAGE_VERSION is $PACKAGE_VERSION"
  echo "  DEBIAN_REVISION_NUMBER is $DEBIAN_REVISION_NUMBER"
  echo "  YCM_PACKAGE is $YCM_PACKAGE"
  echo "  SUPPORTED_DISTRO_LIST is $SUPPORTED_DISTRO_LIST"
  echo "  SUPPORTED_TARGET_LIST is $SUPPORTED_TARGET_LIST"
  echo "  CMAKE_MIN_REQ_VER is $CMAKE_MIN_REQ_VER"
  echo "  ICUB_DEPS_COMMON is $ICUB_DEPS_COMMON"
  echo "  ICUB_REPO_URL is $ICUB_REPO_URL"
  echo "  ICUB_PACKAGE_MAINTAINER is $ICUB_PACKAGE_MAINTAINER"
  echo "  _EQUIVS_BIN is $_EQUIVS_BIN"
  echo " _PLATFORM_KEY is $_PLATFORM_KEY"
  echo " _CONTROL_FILE is $_CONTROL_FILE "
}

usage ()
{
  echo "SCRIPT DESCRIPTION"

  echo "Usage: $0 [options]"
  echo "options are :"
  echo "  -V PACKAGE_VERSION : use PACKAGE_VERSION as version for metapackage"
  echo "  -R DEBIAN_REVISION_NUMBER : use DEBIAN_REVISION_NUMBER ad revision for metapackage"
  echo "  -l LOG_FILE : write logs to file LOG_FILE"
  echo "  -d : print defaults"
  echo "  -v : print version"
  echo "  -h : print this help"
}

log() {
 if [ "$LOG_FILE" != "" ]
  then
    echo -e "$(date +%d-%m-%Y) - $(date +%H:%M:%S) : ${1}${COL_NORMAL}" >> $LOG_FILE
  else
    echo -e "$(date +%d-%m-%Y) - $(date +%H:%M:%S) : ${1}${COL_NORMAL}"
  fi
}

warn() {
  log "${COL_WARNING}WARNING - $1"
 }

error() {
  log "${COL_ERROR}ERROR - $1"
}

exit_err () {
  error "$1"
  exit 1
}

print_version() {
    echo "Script version is $SCRIPT_VERSION based of Template version $SCRIPT_TEMPLATE_VERSION"
}

parse_opt() {
  while getopts hdvl:V:R: opt
  do
    case "$opt" in
    "V")
      PACKAGE_VERSION="$OPTARG"
      ;;
    "R")
      DEBIAN_REVISION_NUMBER="$OPTARG"
      ;;
    "l")
      LOG_FILE="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    d)
      print_defs
      exit 0
      ;;
    v)
      print_version
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
  if [ "$_PLATFORM_KEY" == "" ]; then
    exit_err "unable to read platform key"
  fi

  if [ "$PLATFORM_HARDWARE" == "" ]; then
    exit_err "unable to read hardware key"
  fi

  if [ "$PACKAGE_VERSION" == "" ]; then
    exit_err "Package version string is empty"
  fi

  if [ "$DEBIAN_REVISION_NUMBER" == "" ]; then
    exit_err "Package revision string is empty"
  fi

  if [[ ! "$SUPPORTED_DISTRO_LIST" =~ "$_PLATFORM_KEY" ]]; then
    exit_err "Distro $_PLATFORM_KEY is not supported, we support only $SUPPORTED_DISTRO_LIST"
  fi

  if [[ ! "$SUPPORTED_TARGET_LIST" =~ "$PLATFORM_HARDWARE" ]]; then
    exit_err "Distro $PLATFORM_HARDWARE is not supported, we support only $SUPPORTED_TARGET_LIST"
  fi

  log "$0 ${COL_OK}STARTED"
}

fini()
{
  if [ -f "$_CONTROL_FILE" ];
    rm "$_CONTROL_FILE"
  fi

  log "$0 ${COL_OK}ENDED"
}

check_and_install_deps()
{
  if [ "$_EQUIVS_BIN" == "" ]; then
    sudo apt install -y equivs
  fi
}

create_control_file()
{
  _ICUB_COMMON_DEPENDENCIES=""
  for dep in $ICUB_DEPS_COMMON ; do
    if [ "$_ICUB_COMMON_DEPENDENCIES" == "" ]; then
      _ICUB_COMMON_DEPENDENCIES="$dep"
    else
      _ICUB_COMMON_DEPENDENCIES="${_ICUB_COMMON_DEPENDENCIES}, $dep"
    fi
  done
  _PLAT_DEPS_TAG="ICUB_DEPS_${_PLATFORM_KEY}"
  for pdep in ${!_PLAT_DEPS_TAG} ; do
    if [ "$_ICUB_COMMON_DEPENDENCIES" == "" ]; then
      _ICUB_COMMON_DEPENDENCIES="$pdep"
    else
      _ICUB_COMMON_DEPENDENCIES="${_ICUB_COMMON_DEPENDENCIES}, $pdep"
    fi
  done
  echo "Package: icub-common
Version: ${PACKAGE_VERSION}-${DEBIAN_REVISION_NUMBER}~${_PLATFORM_KEY}
Section: contrib/science
Priority: optional
Architecture: $PLATFORM_HARDWARE
Depends: $ICUB_COMMON_DEPENDENCIES, cmake (>=${CMAKE_MIN_REQ_VER})
Homepage: http://www.icub.org
Maintainer: ${ICUB_PACKAGE_MAINTAINER}
Description: List of dependencies for iCub software (metapackage)
 This metapackage lists all the dependencies needed to install the icub platform software or to download the source code and compile it directly onto your machine." | sudo tee $_CONTROL_FILE

}

create_deb()
{
  $_EQUIVS_BIN $_CONTROL_FILE
}

main()
{
  check_and_install_deps
  create_control_file
  create_deb
}

parse_opt "$@"
init
main
fini
exit 0
