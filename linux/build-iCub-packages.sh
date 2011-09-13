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


#-------------------------------------------------------------------------------------#
# Helper for running a command within the build chroot
function run_in_chroot 
{
	sudo dchroot -c $CHROOT_NAME --directory=/ "$1"
}

# Helper for smooth exit (unmounting /proc)
function do_exit 
{
	run_in_chroot "umount /proc"
	exit $1
}
#-------------------------------------------------------------------------------------#

if [ "K${1}" = "K" ]; then
	echo "Please insert path to the yarp builds."
	exit 1
fi

if [ "K${2}" = "K" ]; then
	echo "Please insert chroot name."
	exit 1
fi

# ROOT_DIR in this case is simply /exports/
ROOT_DIR=$1
CHROOT_NAME=$2
YARP_SCRIPT_DIR=$ROOT_DIR/linux-yarp-packaging/			# symlink to link folder extracted from yarp svn.
ICUB_SCRIPT_DIR=$PWD/									# folder in which this file is located.	

BUILD_DIR=$ROOT_DIR/build/

source $ICUB_SCRIPT_DIR/config.sh						# Load ICUB_VERSION & DEBIAN_REVISION_NUMBER variables
ICUB_VERSION_NAME=iCub$ICUB_VERSION

source $BUILD_DIR/settings.sh							# Load BUNDLE_NAME variable - written by yarp scripts
source $YARP_SCRIPT_DIR/conf/$BUNDLE_NAME.sh			# Load YARP_VERSION variable - written by yarp scripts

# 	Variables used in the script and sourced directly from yarp packaging files
# DEBIAN_REVISION_NUMBER								-> comes from ICUB_SCRIPT_DIR/version.sh
# YARP_PACKAGE_DIR=$BUILD_ROOT/yarp_${CHROOT_NAME}		-> comes from yarp_distro.sh file inside BUILD_DIR
# YARP_PACKAGE=yarp-${YARP_VERSION}-${PLATFORM_KEY}-${PLATFORM_HARDWARE}.deb
# CHROOT_NAME=$BUILD_DIR/chroot_${CHROOT_NAME}   		-> comes from chroot_distro.sh file inside BUILD_DIR
# CHROOT_DIR=$BUILD_DIR/chroot_${CHROOT_NAME}    		-> comes from chroot_distro.sh file inside BUILD_DIR

echo -e "\nPrint debug information\n"
echo "Path to the yarp scripts is $YARP_SCRIPT_DIR"
echo "Path to the yarp builds  is $ICUB_SCRIPT_DIR"

#-------------------------------------------------------------------------------------#
# Variable to be used INSIDE chroots

CMAKE=cmake
D_ICUB_ROOT=/tmp/$ICUB_VERSION_NAME/main
D_ICUB_DIR=$D_ICUB_ROOT/build
D_ICUB_INSTALL_DIR=/tmp/install_dir/$ICUB_VERSION_NAME
echo "ICUB_VERSION_NAME = $ICUB_VERSION_NAME"
echo "ICUB_DIR = $D_ICUB_DIR"
echo "ICUB_INSTALL_DIR = $D_ICUB_INSTALL_DIR"

#-------------------------------------------------------------------------------------#

echo "Yarp version = $YARP_VERSION"					# Need yarp version to see if it matches the icub requirement

#for i in "$BUILD_DIR"/chroot_*.sh
#do

source $BUILD_DIR/chroot_${CHROOT_NAME}.sh			# Load CHROOT_NAME & CHROOT_DIR for current distro+arch
source $BUILD_DIR/yarp_${CHROOT_NAME}.sh   			# Load YARP_PACKAGE_DIR & YARP_PACKAGE_NAME for current distro+arch
source $BUILD_DIR/config_${CHROOT_NAME}.sh			# Load PLATFORM_KEY & PLATFORM_HARDWARE
echo "Path to yarp is: $YARP_PACKAGE_DIR"

YARP_BUILD_CHROOT=$YARP_PACKAGE_DIR/build_chroot
YARP_TEST_CHROOT=$YARP_PACKAGE_DIR/test_chroot
ICUB_BUILD_CHROOT=$YARP_PACKAGE_DIR/test_chroot

# Configure dchroot file
## tee command is needed because "sudo >>" doesn't work!!
cat  /etc/dchroot.conf | grep -i "$CHROOT_NAME"
if [ $? = 0 ]; then
	echo "/etc/dchroot.conf $CHROOT_NAME entry already exists."
else
	echo "$CHROOT_NAME $ICUB_BUILD_CHROOT" | sudo tee -a /etc/dchroot.conf > /dev/null
fi

#echo "$CHROOT_NAME $ICUB_BUILD_CHROOT" >> dchroot.conf
#sudo cp dchroot.conf /etc/

LOG_FILE=$ICUB_SCRIPT_DIR/log/$CHROOT_NAME.log
echo -e "$CHROOT_NAME; log file=$LOG_FILE\n.\n"
DEBIAN_REVISION="${DEBIAN_REVISION_NUMBER}~${PLATFORM_KEY}+${PLATFORM_HARDWARE}"
PACKAGE_NAME=$ICUB_VERSION_NAME-$DEBIAN_REVISION.deb


run_in_chroot "mount -t proc proc /proc" >> $LOG_FILE 2>&1

			 ###------------------- ICUB --------------------###
echo        "###------------------- ICUB --------------------###"
echo -e "\n\n###------------------- ICUB --------------------###\n\n" >> $LOG_FILE 2>&1

# Check if test_XXX make target has been made
if [ ! -e $BUILD_DIR/test_${CHROOT_NAME}.txt ]; then
	echo "yarp test_${CHROOT_NAME}.txt has not been found, skipping this one."
	do_exit "1"
else
	echo "yarp test_${CHROOT_NAME}.txt has been found!!... OK"
fi

# Check if test_chroot folder actually exists
if [ ! -d $YARP_TEST_CHROOT ]; then
	echo "${CHROOT_NAME} test_chroot ($YARP_TEST_CHROOT) has not been found, skipping this one."
	do_exit "2"
else
	echo "${CHROOT_NAME} test_chroot ($YARP_TEST_CHROOT) has been found!!... OK"
fi

# install ICUB dependencies
run_in_chroot "apt-get install $APT_OPTIONS cmake wget subversion subversion"  >> $LOG_FILE 2>&1

ICUB_DEPENDENCIES="libncurses5-dev  libglademm-2.4-dev libqt3-mt-dev  libcv-dev libhighgui-dev libcvaux-dev"
echo "Installing dependencies : $ICUB_DEPENDENCIES"
run_in_chroot "apt-get install $APT_OPTIONS $ICUB_DEPENDENCIES" >> $LOG_FILE 2>&1

echo "Fetching iCub tag $ICUB_VERSION_NAME"
run_in_chroot "cd /tmp; echo p | svn co $SVN_OPTIONS https://robotcub.svn.sourceforge.net/svnroot/robotcub/tags/$ICUB_VERSION_NAME/ $ICUB_VERSION_NAME" >> $LOG_FILE 2>&1
	
# Search which version of yarp is required
STRING=$(cat "$ICUB_BUILD_CHROOT/tmp/$ICUB_VERSION_NAME/main/CMakeLists.txt" | grep ICUB_REQYARP_VERSION)
TMP=$(echo $STRING | awk '{ split($0, array, "MAJOR" ); print array[2] }')
ICUB_REQYARP_VERSION_MAJOR=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')

TMP=$(echo $STRING | awk '{ split($0, array, "MINOR" ); print array[2] }')
ICUB_REQYARP_VERSION_MINOR=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')

TMP=$(echo $STRING | awk '{ split($0, array, "PATCH" ); print array[2] }')
ICUB_REQYARP_VERSION_PATCH=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')

echo "major= $ICUB_REQYARP_VERSION_MAJOR"
echo "minor= $ICUB_REQYARP_VERSION_MINOR"
echo "patch= $ICUB_REQYARP_VERSION_PATCH"

ICUB_REQYARP_VERSION=$ICUB_REQYARP_VERSION_MAJOR.$ICUB_REQYARP_VERSION_MINOR.$ICUB_REQYARP_VERSION_PATCH
echo "ICUB_REQYARP_VERSION=$ICUB_REQYARP_VERSION"
echo "Found Yarp version = $YARP_VERSION"

echo "$ICUB_REQYARP_VERSION $YARP_VERSION" | awk '{ if($2 >= $1) exit 11 }'

if [ $? = 11 ]; then
	echo "compatible YARP_VERSION version found."
else
	echo "YARP_VERSION version too old, update it please!! exiting"
	do_exit "3"
fi

# Go ahead and configure
echo "Configuring iCub"
run_in_chroot "mkdir -p $D_ICUB_DIR; cd $D_ICUB_DIR; export ICUB_ROOT=$D_ICUB_INSTALL_DIR/usr/share/iCub; $CMAKE -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$D_ICUB_INSTALL_DIR/usr/ $D_ICUB_ROOT" >> $LOG_FILE 2>&1


# Go ahead and make
echo "Compiling iCub"
run_in_chroot "cd $D_ICUB_DIR; make" >> $LOG_FILE 2>&1

# make install
echo "make install"
run_in_chroot "cd $D_ICUB_DIR; make install" >> $LOG_FILE 2>&1
	
# make install_applications
echo "make install_applications"
run_in_chroot "cd $D_ICUB_DIR; make install_applications" >> $LOG_FILE 2>&1

# install ICUB simulator dependencies
echo "PLATFORM_KEY is $PLATFORM_KEY"
if [ $PLATFORM_KEY = "lenny" ] || [ $PLATFORM_KEY = "lucid" ]; then
	# we need to download and compile libode manually
	SIM_DEPENDENCIES="libglut3-dev libsdl1.2-dev unzip "
	echo "Installing dependencies : $SIM_DEPENDENCIES"
	run_in_chroot "apt-get install $APT_OPTIONS $SIM_DEPENDENCIES" >> $LOG_FILE 2>&1
	
	# Get ODE library and compile it
	if [ ! -d $ICUB_BUILD_CHROOT/tmp/ode-0.11.1 ]; then
		run_in_chroot "cd /tmp && wget http://sourceforge.net/projects/opende/files/ODE/0.11.1/ode-0.11.1.zip && unzip ode-0.11.1.zip >> /dev/null" >> $LOG_FILE 2>&1
		run_in_chroot "cd /tmp/ode-0.11.1 && ./configure --prefix=/usr --enable-double-precision --enable-shared --disable-drawstuff --disable-demos && make && make install" >> $LOG_FILE 2>&1

	else
		echo "libode already installed"
	fi
	
else  # if linux version is squeeze or maverick (and newer I hope), libode from synaptic is ok!
	SIM_DEPENDENCIES="libglut3-dev libsdl1.2-dev libode-dev"
	echo "Installing dependencies : $SIM_DEPENDENCIES"
	run_in_chroot "apt-get install $APT_OPTIONS $SIM_DEPENDENCIES" >> $LOG_FILE 2>&1
fi

# Go ahead and configure
run_in_chroot "mkdir -p $D_ICUB_DIR; cd $D_ICUB_DIR; export ICUB_ROOT=$D_ICUB_INSTALL_DIR/usr/share/iCub; $CMAKE -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$D_ICUB_INSTALL_DIR/usr/ -DICUB_USE_SDL=ON -DICUB_USE_ODE=ON -DICUB_SIM_OLD_RESPONDER=ON -DICUB_SIM_OMIT_LOGPOLAR=ON -DICUB_USE_GLUT=ON -DICUB_APPLICATIONS_PREFIX=$D_ICUB_INSTALL_DIR/usr/share/iCub $D_ICUB_ROOT" >> $LOG_FILE 2>&1

# Go ahead and make
run_in_chroot "cd $D_ICUB_DIR; make" >> $LOG_FILE 2>&1

# make install
run_in_chroot "cd $D_ICUB_DIR; make install" >> $LOG_FILE 2>&1

# make install applications
run_in_chroot "cd $D_ICUB_DIR; make install_applications" >> $LOG_FILE 2>&1

SIZE=$(du -s $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/)
SIZE=$(echo $SIZE | awk '{ split($0, array, "/" ); print array[1] }')
echo "Size: $SIZE"

# Generate dpkg DEBIAN folder
run_in_chroot "mkdir -p $D_ICUB_INSTALL_DIR/DEBIAN"

# Remove standard ICUB_ROOT.ini file and substitute it with the ad-hoc one.
run_in_chroot "rm $D_ICUB_INSTALL_DIR/usr/share/iCub/ICUB_ROOT.ini"

#echo "mkdir -p $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/; cp $ICUB_SCRIPT_DIR/ICUB_ROOT.ini $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/"
sudo mkdir -p $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/
sudo cp $ICUB_SCRIPT_DIR/ICUB_ROOT.ini $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/

# Generate 'conffiles' file
sudo touch $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/conffiles
echo "/etc/ICUB_ROOT.ini" | sudo tee $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/conffiles

# Generate DEBIAN/md5sums file
if [ -f $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums ]; then
	echo "Removing old md5sums file in $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/"
	sudo rm $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums
fi
sudo touch $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums

cd $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR
FILES=$(find -path ./DEBIAN -prune -o -print)
for FILE in $FILES
do
	#echo $FILE >> /data/list.txt
	if [ ! -d $FILE ]; then
		md5sum $FILE | sudo tee -a $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums  >> /dev/null
	fi
done

# Generate dpkg DEBIAN/control file 
run_in_chroot "mkdir -p $D_ICUB_INSTALL_DIR/DEBIAN; touch $D_ICUB_INSTALL_DIR/DEBIAN/control" >> $LOG_FILE 2>&1

# if ode is not got from repository don't list it in the dependencies
DEPENDS_ON="libc6, python (<= 3), libncurses5-dev,  libglademm-2.4-dev, libqt3-mt-dev,  libcv-dev, libhighgui-dev, libcvaux-dev, yarp ( >= $ICUB_REQYARP_VERSION)"

if [ $PLATFORM_KEY = "lenny" ] || [ $PLATFORM_KEY = "lucid" ]; then
	# nothing, ode can't be listed
	echo "working on $PLATFORM_KEY, so won't add libode to the dependencies"
else
	DEPENDS_ON="$DEPENDS_ON, libode1 (>= 0.11.1)"
fi


# Create dependencies package
mkdir -p $ICUB_BUILD_CHROOT/tmp/install_dir/icub-common${ICUB_VERSION}
echo "Generating package"
echo "Package: icub-common
Version: $ICUB_VERSION-$DEBIAN_REVISION
Section: contrib/science
Priority: optional
Architecture: $PLATFORM_HARDWARE
Depends: $DEPENDS_ON
Installed-Size:  $SIZE
Homepage: http://www.robotcub.org
Maintainer: Alberto Cardellino <alberto.cardellino@iit.it>
Description: List of dependencies for iCub software
 This package lists all the dependencies needed to install the icub 
 platform software or to download the source code and compile it directly
 onto your machine." | sudo tee $ICUB_BUILD_CHROOT/tmp/install_dir/icub-common${ICUB_VERSION}/DEBIAN/control
 
run_in_chroot "cd tmp/install_dir; dpkg -b icub-common${ICUB_VERSION} icub-common${ICUB_VERSION}.deb"
 
run_in_chroot "cp /tpm/$ICUB_VERSION_NAME/main/COPYING $D_ICUB_INSTALL_DIR/usr/share/doc/icub/copyright"
run_in_chroot "cp /tpm/$ICUB_VERSION_NAME/main/AUTHORS $D_ICUB_INSTALL_DIR/usr/share/doc/icub/AUTHORS"
 
echo "Generating package"
echo "Package: icub
Version: $ICUB_VERSION-$DEBIAN_REVISION
Section: contrib/science
Priority: optional
Architecture: $PLATFORM_HARDWARE
Depends: icub-common ( = $ICUB_VERSION)
Installed-Size:  $SIZE
Homepage: http://www.robotcub.org
Maintainer: Alberto Cardellino <alberto.cardellino@iit.it>
Description: Software platform for iCub humanoid robot with simulator.
 The iCub is the humanoid robot developed as part of the EU project RobotCub and 
 subsequently adopted by more than 20 laboratories worldwide. It has 53 motors 
 that move the head, arms & hands, waist, and legs. It can see and hear, it has 
 the sense of proprioception and movement.
 .
 This package provides the standard iCub software platform and apps to interact
 with the real iCub robot, or with the included simulator." | sudo tee $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/control
 
# Fix permission for scripts
#/$ICUB_SCRIPT_DIR/fix_script_perm.sh $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR

# Fix path inside cmake files
sudo /$ICUB_SCRIPT_DIR/fix_cmake_path.sh $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR  $ICUB_VERSION_NAME

# Build package
run_in_chroot "cd /tmp/install_dir; dpkg -b $ICUB_VERSION_NAME $PACKAGE_NAME"	>> $LOG_FILE 2>&1

# Copy .deb to somewhere easier to find
echo -e "\n\n cp $ICUB_BUILD_CHROOT/tmp/install_dir/$PACKAGE_NAME $YARP_PACKAGE_DIR/ \n\n"
sudo cp $ICUB_BUILD_CHROOT/tmp/install_dir/$PACKAGE_NAME $YARP_PACKAGE_DIR/  	>> $LOG_FILE 2>&1

# Copy deb into shared folder for VM
echo "Copying yarp and iCub debs to shared folder /data/debs/$CHROOT_NAME/ "
mkdir -p /data/debs/$CHROOT_NAME
cp $YARP_PACKAGE_DIR/$PACKAGE_NAME /data/debs/$CHROOT_NAME/
cp $YARP_PACKAGE_DIR/yarp*.deb	/data/debs/$CHROOT_NAME/

# Test the package with lintian
echo "Testing icub package with lintian "
lintian $YARP_PACKAGE_DIR/$PACKAGE_NAME > $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.log
lintian-info $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.log > $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.info

echo "Installing package"
run_in_chroot "dpkg -i /tmp/install_dir/$PACKAGE_NAME" >> $LOG_FILE 2>&1

# very simple test
echo "Testing: icubmoddev --list"
run_in_chroot "icubmoddev --list"		>> $LOG_FILE 2>&1

# try to run iCub_SIM
run_in_chroot "yarpserver3 &"  			>> $LOG_FILE 2>&1
run_in_chroot "iCub_SIM"  				>> $LOG_FILE 2>&1

sleep 10
echo "kill all"
echo "kill all" >> $LOG_FILE 2>&1
sudo killall iCub_SIM
sudo killall yarpserver3

run_in_chroot "umount /proc" 			>> $LOG_FILE 2>&1
