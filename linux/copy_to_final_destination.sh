# /bin/bash
#
# Aim of this script: copy the created debs to Ale.
#
# This script is intended to be run as the last part of the build process, taking the results
# of the build and copying them elsewhere. It uses variables created during the prepare phase.
# In order to run this script by itself, uncomment the following command, changing the last 
# parameter to match the DISTRO_ARCH you want to copy.

# source ./prepare.sh /data lucid_i386

# In this latter case, you'll see an error for a missing file, don't bother about that, it's
# not needed in this script.

## -------------------------  Copying debs elsewhere REMOTELY ---------------------------------- ##  	

# Copy debs into my home directory on geo repository, to make Alessandro Bruchi's life easier.

echo "PLATFORM_IS_DEBIAN=$PLATFORM_IS_DEBIAN; PLATFORM_IS_UBUNTU=$PLATFORM_IS_UBUNTU"
if [ "K$PLATFORM_IS_DEBIAN" = "Ktrue" ]; then
	DISTRO=debian
elif [ "K$PLATFORM_IS_UBUNTU" = "Ktrue" ]; then
	DISTRO=ubuntu
else
	echo " | | ERROR!! Not PLATFORM_IS_DEBIAN nor PLATFORM_IS_UBUNTU defined -> Unknown platform"
	echo " > > Do not run this script directly, use 'RunThemAll /data copy' instead"
	exit 1
fi

echo "Distro= $DISTRO"

# make sure destination folder do exists
ssh cardellino@geo "mkdir -p repository/$DISTRO/pool/$PLATFORM_KEY/contrib/science/$PLATFORM_HARDWARE"
# copying yarp deb
echo "scp $YARP_PACKAGE_DIR/yarp*.deb   ../repository/$DISTRO/pool/$PLATFORM_KEY/contrib/science/$PLATFORM_HARDWARE"
scp $YARP_PACKAGE_DIR/yarp*.deb   ../repository/$DISTRO/pool/$PLATFORM_KEY/contrib/science/$PLATFORM_HARDWARE
# copying iCub debs 
echo "scp $ICUB_BUILD_CHROOT/tmp/install_dir/iCub*.deb   ../repository/$DISTRO/pool/$PLATFORM_KEY/contrib/science/$PLATFORM_HARDWARE"
scp $ICUB_BUILD_CHROOT/tmp/install_dir/iCub*.deb   ../repository/$DISTRO/pool/$PLATFORM_KEY/contrib/science/$PLATFORM_HARDWARE

#Copy debs to folders synched with sourceforge
echo "-------------"
echo "Copying stuff to sourceforge"
echo "-------------"

ssh cardellino@geo "mkdir -p sourceforge/$YARP_VERSION_NAME/linux; mkdir -p sourceforge/$ICUB_VERSION_NAME/linux"
	#echo "scp $YARP_PACKAGE_DIR/$YARP_PACKAGE_NAME   cardellino@geo:~/sourceforge/$YARP_PACKAGE_NAME"
scp $YARP_PACKAGE_DIR/$YARP_PACKAGE_NAME   cardellino@geo:~/sourceforge/$YARP_VERSION_NAME/linux/$YARP_PACKAGE_NAME

	#echo "scp $ICUB_BUILD_CHROOT/$ICUB_VERSION_NAME*.deb   cardellino@geo:~/sourceforge/$ICUB_VERSION_NAME"
scp $ICUB_BUILD_CHROOT/tmp/install_dir/$ICUB_VERSION_NAME*.deb   ../sourceforge/$ICUB_VERSION_NAME/linux/
scp $ICUB_BUILD_CHROOT/tmp/install_dir/$ICUB_COMMON_NAME*.deb   cardellino@geo:~/sourceforge/$ICUB_VERSION_NAME/linux/

