#!/bin/bash
# Passaggi:
# cerca filettini .sh per le varie distro di yarp realizzate
#        parametro $1 = cartella in cui si trovano le build di yarp
# cerca corrispondente test_chroot se esiste
# Scaricare dipendenze
# Scarica icub
# Compila e make install
# Creare pacchetto .deb
# Verifica tramite installazione pacchetto e lancio iCub_SIM

# Se i path sono scorretti, controllare (o rimuovere) /etc/dchroot.conf

#--------------------------------- Helpers --------------------------------------------------------------#
# Helper for running a command within the build chroot
function run_in_chroot 
{
	sudo dchroot -c $CHROOT_NAME --directory=/ "$1"
}

function DO
{
	echo "$1"
	$1
}

# Helper for smooth exit (unmounting /proc)
function do_exit 
{
	run_in_chroot "umount /proc"
	exit $1
}

#---------------------------------- Check input values ---------------------------------------------------#
# 

cd "`dirname $0`"
echo $PWD
ICUB_SCRIPT_DIR=$PWD
cd $OLDPWD


# $1 is ROOT_DIR, in this case simply /data/
if [ "K${1}" = "K" ]; then
	echo " | | Please insert path to the yarp builds."
	exit 1
fi

if [ "K${2}" = "K" ]; then
	echo " | | Please insert chroot name."
	exit 1
fi

ROOT_DIR=$1
CHROOT_NAME=$2

#---------------------------------------- basic useful folders ---------------------------------------------#

BUILD_DIR=$ROOT_DIR/build/
YARP_SCRIPT_DIR=$ROOT_DIR/linux-yarp-packaging/			# symlink to link folder extracted from yarp svn.

#---------------------------------------- source yarp configs ---------------------------------------------#
source $BUILD_DIR/chroot_${CHROOT_NAME}.sh			# Load CHROOT_NAME & CHROOT_DIR for current distro+arch
source $BUILD_DIR/yarp_${CHROOT_NAME}.sh   			# Load YARP_PACKAGE_DIR & YARP_PACKAGE_NAME for current distro+arch
source $BUILD_DIR/config_${CHROOT_NAME}.sh			# Load PLATFORM_KEY & PLATFORM_HARDWARE

#---------------------------------------- source icub configs ---------------------------------------------#
source $ICUB_SCRIPT_DIR/config.sh						# Load ICUB_VERSION & DEBIAN_REVISION_NUMBER variables
source $BUILD_DIR/settings.sh							# Load BUNDLE_NAME variable - written by yarp scripts
source $YARP_SCRIPT_DIR/conf/$BUNDLE_NAME.sh			# Load YARP_VERSION variable - written by yarp scripts

if [ "k$3" = "ktest" ]; then
	TESTING="TRUE"
	echo "testing revision $4"
	ICUB_VERSION="rev-$4"
	ICUB_REVISION=$4
else
	echo "using tags"
fi

#----------------------------------- global environment --------------------------------------------------#
# Defining variables to be used in the global environment

# 	Variables used in the script and sourced directly from yarp packaging files
# DEBIAN_REVISION_NUMBER								-> comes from ICUB_SCRIPT_DIR/version.sh
# YARP_PACKAGE_DIR=$BUILD_ROOT/yarp_${CHROOT_NAME}		-> comes from yarp_distro.sh file inside BUILD_DIR
# YARP_PACKAGE=yarp-${YARP_VERSION}-${PLATFORM_KEY}-${PLATFORM_HARDWARE}.deb
# CHROOT_NAME=$BUILD_DIR/chroot_${CHROOT_NAME}   		-> comes from chroot_distro.sh file inside BUILD_DIR
# CHROOT_DIR=$BUILD_DIR/chroot_${CHROOT_NAME}    		-> comes from chroot_distro.sh file inside BUILD_DIR

YARP_BUILD_CHROOT=$YARP_PACKAGE_DIR/build_chroot
YARP_TEST_CHROOT=$YARP_PACKAGE_DIR/test_chroot
ICUB_BUILD_CHROOT=$YARP_PACKAGE_DIR/test_chroot

#----------------------------------- iCub and yarp variables----------------------------------------#

# Yarp version actually installed, split version number in major, minor and patch to simplify comparison
YARP_VERSION_MAJOR=$(echo $YARP_VERSION | awk '{ split($0, array, "." ); print array[1] }')
YARP_VERSION_MINOR=$(echo $YARP_VERSION | awk '{ split($0, array, "." ); print array[2] }')
YARP_VERSION_PATCH=$(echo $YARP_VERSION | awk '{ split($0, array, "." ); print array[3] }')


ICUB_VERSION_NAME=iCub$ICUB_VERSION
DEBIAN_REVISION="${DEBIAN_REVISION_NUMBER}~${PLATFORM_KEY}_${PLATFORM_HARDWARE}"
PACKAGE_NAME=$ICUB_VERSION_NAME-$DEBIAN_REVISION.deb

ICUB_COMMON_VERSION=$ICUB_VERSION-$DEBIAN_REVISION_NUMBER
ICUB_COMMON_NAME=iCub-common${ICUB_COMMON_VERSION}
ICUB_COMMON_PKG_NAME=iCub-common$ICUB_VERSION-$DEBIAN_REVISION

#---------------------------------- DCHROOT environment ---------------------------------------------------#
# Defining variables to be used inside DCHROOT environment

CMAKE=cmake
D_ICUB_ROOT=/tmp/$ICUB_VERSION_NAME/main
D_ICUB_DIR=$D_ICUB_ROOT/build
D_ICUB_INSTALL_DIR=/tmp/install_dir/$ICUB_VERSION_NAME

#-------------------------------------- Others ------------------------------------------#
YARP_VERSION_NAME=yarp-${YARP_VERSION}
YARP_PACKAGE_NAME=$YARP_PACKAGE
# YARP_PACKAGE_NAME=yarp-${YARP_VERSION}-${PLATFORM_KEY}-${PLATFORM_HARDWARE}.deb

