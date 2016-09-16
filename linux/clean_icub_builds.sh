#! /bin/bash
# Passaggi:
# cerca filettini .sh per le varie distro realizzate
#        parametro $1 = cartella in cui si trovano le build di yarp

function DO
{
	echo "$1"
	$1
}


if [ "K${1}" = "K" ]; then
	echo "Please insert path to the yarp builds."
	exit 1
fi

ROOT_DIR=$1

if [ "K${2}" = "K" ]; then
	echo "Please insert chroot_name to clean or 'ALL' to clean all icub builds"
	exit 2
fi
	
if [ "K${2}" = "KALL" ]; then
	echo "Cleaning ALL builds!! Loading list..."

	for i in "${ROOT_DIR}/build"/chroot_*.sh
	do
		source $i																# Load CHROOT_NAME & CHROOT_DIR for current distro+arch
		list="$list $CHROOT_NAME"
	done
else
	list=$2
	source ${ROOT_DIR}/build/chroot_${2}.sh
fi

echo -e "\nBuilds to be cleaned: $list\n"

for i in $list
do
	echo "Cleaning $i..."
	DO "source $ROOT_DIR/build/yarp_${i}.sh"									# Load YARP_PACKAGE_DIR & YARP_PACKAGE_NAME for current distro+arch
	DO "source ${ROOT_DIR}/build/config_${i}.sh"								# Load PLATFORM_KEY & PLATFORM_HARDWARE
	DO "sudo chroot $YARP_PACKAGE_DIR/test_chroot/ dpkg --purge icub"
	DO "sudo chroot $YARP_PACKAGE_DIR/test_chroot/ dpkg --purge icub-common"
	DO "sudo chroot $YARP_PACKAGE_DIR/test_chroot/ umount /proc"
	DO "source $PWD/config.sh"													# Load ICUB_VERSION & DEBIAN_REVISION_NUMBER variables


	if [ "K$PLATFORM_IS_DEBIAN" = "Ktrue" ]; then
		DISTRO=debian
	elif [ "K$PLATFORM_IS_UBUNTU" = "Ktrue" ]; then
		DISTRO=ubuntu
	else
		echo " | | ERROR!! Not PLATFORM_IS_DEBIAN nor PLATFORM_IS_UBUNTU defined -> Unknown platform"
		exit 1
	fi

	#DO "sudo rm   	$YARP_PACKAGE_DIR/iCub*.deb" 
	DO "cd 	$YARP_PACKAGE_DIR/test_chroot/tmp/$IPOPT; sudo make distclean"
	DO "sudo rm -r	$YARP_PACKAGE_DIR/test_chroot/tmp/$IPOPT*"
	DO "sudo rm -r	$YARP_PACKAGE_DIR/test_chroot/tmp/*.done"
	DO "sudo rm -r	$YARP_PACKAGE_DIR/test_chroot/tmp/iCub${ICUB_VERSION}"
	DO "sudo rm -r  $YARP_PACKAGE_DIR/test_chroot/tmp/install_dir"
	DO "sudo rm 	$ROOT_DIR/linux-icub-packaging/log/$i.log"
	DO "sudo rm 	$ROOT_DIR/linux-icub-packaging/log/Lintian*${PLATFORM_KEY}_${PLATFORM_HARDWARE}*.log"
	DO "sudo rm 	$ROOT_DIR/linux-icub-packaging/log/Lintian*${PLATFORM_KEY}_${PLATFORM_HARDWARE}*.info"
#	DO "sudo rm 	$ROOT_DIR/linux-icub-packaging/log/Lintian-iCub-common*${PLATFORM_KEY}+${PLATFORM_HARDWARE}*.log"
#	DO "sudo rm 	$ROOT_DIR/linux-icub-packaging/log/Lintian-iCub-common*${PLATFORM_KEY}+${PLATFORM_HARDWARE}*.info"
	DO "sudo rm 	$ROOT_DIR/debs/$i/iCub*"
	echo -e "done\n"
done

