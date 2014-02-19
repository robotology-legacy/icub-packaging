#!/bin/bash
# Passaggi:
# cerca filettini .sh per le varie distro realizzate
#        parametro $1 = cartella in cui si trovano le build di yarp
SVN_REVISION=""

if [ "K${1}" = "K" ]; then
	echo "Please insert path to the yarp builds."
	exit 1
fi

ROOT_DIR=$1
HERE="`dirname $0`"
cd $HERE


if [ "$2" == "copy" ]; then
	echo "copying..."
	for i in "${ROOT_DIR}"/build/chroot_*.sh
	do
		source $i												# Load CHROOT_NAME & CHROOT_DIR for current distro+arch
		source $HERE/prepare.sh $ROOT_DIR $CHROOT_NAME
		echo "${HERE}/copy_to_final_destination.sh"
		source ${HERE}/copy_to_final_destination.sh
		echo -e "\n runthemall: PLATFORM_IS_DEBIAN=$PLATFORM_IS_DEBIAN; PLATFORM_IS_UBUNTU=$PLATFORM_IS_UBUNTU"
	PLATFORM_IS_DEBIAN=false;
	PLATFORM_IS_UBUNTU=false;
	done

	exit 1
else

sudo rm /etc/dchroot.conf
for i in "${ROOT_DIR}/build"/chroot_*.sh
do
	source $i # Load CHROOT_NAME & CHROOT_DIR for current distro+arch
	if [ "$SVN_REVISION" == "" ]
	then
		echo "${HERE}/build-iCub-packages.sh $ROOT_DIR $CHROOT_NAME"  >> 14RuleThemAll.log
		${HERE}/build-iCub-packages.sh $ROOT_DIR $CHROOT_NAME >> 14RuleThemAll.log
	else
		echo "${HERE}/build-iCub-packages.sh $ROOT_DIR $CHROOT_NAME test $SVN_REVISION"  >> 14RuleThemAll.log
		${HERE}/build-iCub-packages.sh $ROOT_DIR $CHROOT_NAME test $SVN_REVISION>> 14RuleThemAll.log
	fi
done

fi
