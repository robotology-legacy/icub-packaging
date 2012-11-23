# Load everything needed from external files
cd "`dirname $0`"
echo $PWD
ICUB_SCRIPT_DIR=$PWD
cd $OLDPWD
source $ICUB_SCRIPT_DIR/prepare.sh



#----------------------------------- Debug variables------------------------------------------------#

LOG_FILE=$ICUB_SCRIPT_DIR/log/$CHROOT_NAME.log
#LOG_FILE=/dev/stdout

echo -e "Printing debug information\n"					> $LOG_FILE 2>&1

echo "ICUB_VERSION_NAME = $ICUB_VERSION_NAME"			>> $LOG_FILE 2>&1
echo "ICUB_DIR = $D_ICUB_DIR"							>> $LOG_FILE 2>&1
echo "ICUB_INSTALL_DIR = $D_ICUB_INSTALL_DIR"			>> $LOG_FILE 2>&1

echo "Path to yarp is: $YARP_PACKAGE_DIR"				>> $LOG_FILE 2>&1

echo "Path to the yarp scripts is $YARP_SCRIPT_DIR"		>> $LOG_FILE 2>&1
echo "Path to the yarp builds  is $ICUB_SCRIPT_DIR"		>> $LOG_FILE 2>&1
echo -e "$CHROOT_NAME; log file=$LOG_FILE\n"			>> $LOG_FILE 2>&1

echo "Yarp version = $YARP_VERSION"						>> $LOG_FILE 2>&1	# Need yarp version to see if it matches the icub requirement
echo "YARP_VERSION_MAJOR= $YARP_VERSION_MAJOR"			>> $LOG_FILE 2>&1
echo "YARP_VERSION_MINOR= $YARP_VERSION_MINOR"			>> $LOG_FILE 2>&1
echo "YARP_VERSION_PATCH= $YARP_VERSION_PATCH"			>> $LOG_FILE 2>&1

echo "ICUB_SCRIPT_DIR= $ICUB_SCRIPT_DIR"

if [ -e $ICUB_SCRIPT_DIR/stop ]; then
	echo "ok" >> $ICUB_SCRIPT_DIR/stop
	exit 0
fi


#-------------------------------------------------------------------------------------#

# Configure dchroot file
## tee command is needed because "sudo >>" doesn't work!!
sudo touch /etc/dchroot.conf
cat  /etc/dchroot.conf | grep -i "$CHROOT_NAME"
if [ $? = 0 ]; then
	echo "/etc/dchroot.conf $CHROOT_NAME entry already exists."					>> $LOG_FILE 2>&1
else
	echo "$CHROOT_NAME $ICUB_BUILD_CHROOT" | sudo tee -a /etc/dchroot.conf 		>> $LOG_FILE 2>&1
fi

run_in_chroot "mount -t proc proc /proc" >> $LOG_FILE 2>&1

			 ###------------------- Preparing --------------------###
echo        "###------------------- Preparing --------------------###"
echo -e "\n\n###------------------- Preparing --------------------###\n\n" 			>> $LOG_FILE 2>&1

# Check if test_CHROOT_NAME make target has been made
if [ ! -e $BUILD_DIR/test_${CHROOT_NAME}.txt ]; then
	echo " | | ERROR: yarp test_${CHROOT_NAME}.txt has not been found, exiting!"
	do_exit "1"
else
	echo "@ yarp test_${CHROOT_NAME}.txt has been found! OK"
fi

# Check if test_chroot folder actually exists
if [ ! -d $YARP_TEST_CHROOT ]; then
	echo " | | ERROR: ${CHROOT_NAME} test_chroot ($YARP_TEST_CHROOT) has not been found, exiting!"
	do_exit "2"
else
	echo "@ ${CHROOT_NAME} test_chroot ($YARP_TEST_CHROOT) has been found! OK"
fi

# --> Handle (install) ALL dependencies at the beginning
echo "Installing all dependencies in the dchroot environment"					>> $LOG_FILE 2>&1
run_in_chroot "apt-get $APT_OPTIONS install -f"									>> $LOG_FILE 2>&1
run_in_chroot "apt-get install $APT_OPTIONS $BUILD_DEPENDENCIES"  				>> $LOG_FILE 2>&1
run_in_chroot "apt-get $APT_OPTIONS install -f"												>> $LOG_FILE 2>&1

echo        "###------------------- Handle libode --------------------###"
echo -e "\n\n###------------------- Handle libode --------------------###\n\n" 	>> $LOG_FILE 2>&1
# --> Handle libode 
echo "PLATFORM_KEY is $PLATFORM_KEY"											>> $LOG_FILE 2>&1
if [ $PLATFORM_KEY = "lenny" ] || [ $PLATFORM_KEY = "lucid" ]; then
	# We need to download and compile libode manually
	if [ ! -e $ICUB_BUILD_CHROOT/tmp/libode.done ]; then
		run_in_chroot "cd /tmp && wget http://sourceforge.net/projects/opende/files/ODE/0.11.1/ode-0.11.1.zip && echo A | unzip ode-0.11.1.zip >> /dev/null" >> $LOG_FILE 2>&1
		run_in_chroot "cd /tmp/ode-0.11.1 && ./configure --prefix=/usr --enable-double-precision --enable-shared --disable-drawstuff --disable-demos && make && make install" >> $LOG_FILE 2>&1
		sudo touch  $ICUB_BUILD_CHROOT/tmp/libode.done
		echo "libode done"																						>> $LOG_FILE 2>&1
	else
		echo "libode already installed"																			>> $LOG_FILE 2>&1
	fi
	
else  # if linux version is squeeze or maverick (and newer too, hopefully), libode from synaptic is ok!
	echo "Installing libode-dev"																				>> $LOG_FILE 2>&1
	run_in_chroot "apt-get $APT_OPTIONS install -f"																			>> $LOG_FILE 2>&1
	run_in_chroot "apt-get install $APT_OPTIONS libode-dev"														>> $LOG_FILE 2>&1
	run_in_chroot "apt-get $APT_OPTIONS install -f"																			>> $LOG_FILE 2>&1
	echo "libode done"																							>> $LOG_FILE 2>&1
fi

echo        "###------------------- Handle IpOpt --------------------###"
echo -e "\n\n###------------------- Handle IpOpt --------------------###\n\n" 									>> $LOG_FILE 2>&1
# --> Handle IpOpt using Mumps

if [ ! -e $ICUB_BUILD_CHROOT/tmp/$IPOPT-usr.done ]; then 
	# Compile and install (twice) the lib IpOpt - components Blas, Lapack, Mumps and Metis are already downloaded and placed inside the correct ThirdParty folder
	DO "sudo cp -R $ICUB_SCRIPT_DIR/sources/Ipopt/$IPOPT  $ICUB_BUILD_CHROOT/tmp/"								>> $LOG_FILE 2>&1

	run_in_chroot "cd /tmp/$IPOPT/; mkdir -p build; cd build; ../configure --prefix=/usr"						>> $LOG_FILE 2>&1
	run_in_chroot "cd /tmp/$IPOPT/build; make; make test; make install"											>> $LOG_FILE 2>&1
	sudo touch $ICUB_BUILD_CHROOT/tmp/$IPOPT-usr.done															>> $LOG_FILE 2>&1
else
	echo "IpOpt libraries (/usr) already handled."																>> $LOG_FILE 2>&1
fi

# <-- Handle IpOpt - end
# <-- Handle all dependencies - end


#----------------------------------- Download iCub source to correctly resolve iCub-common's dependencies ----------------------------------------#	
#
echo    "Getting iCub source"
echo -e "\nGetting iCub source\n" 																				>> $LOG_FILE 2>&1

if [ $TESTING ]; then
	echo "Fetching iCub revision $ICUB_REVISION"
	echo "Fetching iCub revision $ICUB_REVISION"																	>> $LOG_FILE 2>&1
	cd $ICUB_SCRIPT_DIR/sources; svn co -r $ICUB_REVISION $SVN_OPTIONS https://robotcub.svn.sourceforge.net/svnroot/robotcub/trunk/iCub/ $ICUB_VERSION_NAME 

else
	echo "Fetching iCub tag "																	
	if [ ! -d $ICUB_SCRIPT_DIR/sources/$ICUB_VERSION_NAME ]; then
		echo "Fetching iCub tag $ICUB_VERSION_NAME"																	>> $LOG_FILE 2>&1
		cd $ICUB_SCRIPT_DIR/sources; svn co $SVN_OPTIONS https://robotcub.svn.sourceforge.net/svnroot/robotcub/tags/$ICUB_VERSION_NAME/ $ICUB_VERSION_NAME >> $LOG_FILE 2>&1
	else
		echo "iCub tag $ICUB_VERSION_NAME already downloaded..."													>> $LOG_FILE 2>&1
	fi
	
fi

	
if [ ! -d $ICUB_BUILD_CHROOT/tmp/$ICUB_VERSION_NAME ]; then
	echo "copying iCub tag $ICUB_VERSION_NAME..."																>> $LOG_FILE 2>&1
	DO "sudo cp -uR $ICUB_SCRIPT_DIR/sources/$ICUB_VERSION_NAME $ICUB_BUILD_CHROOT/tmp/"							>> $LOG_FILE 2>&1
else
	echo "iCub tag $ICUB_VERSION_NAME already copied."															>> $LOG_FILE 2>&1
fi



# Fix cmakelist.txt for version 1.1.7, missing execution permissions for some script
if [ $ICUB_VERSION = "1.1.7" ]; then
	echo "Version 1.1.7- fixing cmakelist"																		>> $LOG_FILE 2>&1
	sudo cp $ICUB_SCRIPT_DIR/sources/CMakeLists_1.1.7.txt $ICUB_BUILD_CHROOT/tmp/$ICUB_VERSION_NAME/main/CMakeLists.txt
else
	# Fix cmakelist.txt for version 1.1.8, missing execution permissions for some script
	if [ $ICUB_VERSION = "1.1.8" ]; then
		echo "Version 1.1.8 - fixing cmakelist"																		>> $LOG_FILE 2>&1
		sudo cp $ICUB_SCRIPT_DIR/sources/CMakeLists_1.1.8.txt $ICUB_BUILD_CHROOT/tmp/$ICUB_VERSION_NAME/main/CMakeLists.txt
	else
		echo "Version higer than 1.1.9, cmakelist ok"																>> $LOG_FILE 2>&1
	fi
fi

# Find which version of yarp is required
STRING=$(cat "$ICUB_BUILD_CHROOT/tmp/$ICUB_VERSION_NAME/main/CMakeLists.txt" | grep ICUB_REQYARP_VERSION)
TMP=$(echo $STRING | awk '{ split($0, array, "MAJOR" ); print array[2] }')
ICUB_REQYARP_VERSION_MAJOR=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')

TMP=$(echo $STRING | awk '{ split($0, array, "MINOR" ); print array[2] }')
ICUB_REQYARP_VERSION_MINOR=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')

TMP=$(echo $STRING | awk '{ split($0, array, "PATCH" ); print array[2] }')
ICUB_REQYARP_VERSION_PATCH=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')

echo "ICUB_REQYARP_VERSION_MAJOR= $ICUB_REQYARP_VERSION_MAJOR"														
echo "ICUB_REQYARP_VERSION_MINOR= $ICUB_REQYARP_VERSION_MINOR"														
echo "ICUB_REQYARP_VERSION_MINOR= $ICUB_REQYARP_VERSION_PATCH"														

ICUB_REQYARP_VERSION=$ICUB_REQYARP_VERSION_MAJOR.$ICUB_REQYARP_VERSION_MINOR.$ICUB_REQYARP_VERSION_PATCH
echo "ICUB_REQYARP_VERSION=$ICUB_REQYARP_VERSION"																	>> $LOG_FILE 2>&1
echo "Found Yarp version = $YARP_VERSION"																			>> $LOG_FILE 2>&1

if [ $YARP_VERSION_MAJOR -lt $ICUB_REQYARP_VERSION_MAJOR ] || [ $YARP_VERSION_MINOR -lt $ICUB_REQYARP_VERSION_MINOR ] || [ $YARP_VERSION_PATCH -lt $ICUB_REQYARP_VERSION_PATCH ]; then
	echo "Your yarp version is too old!! iCub version $ICUB_VERSION requires yarp version $ICUB_REQYARP_VERSION, please update it before proceeding" >> $LOG_FILE 2>&1
	do_exit "3"
fi

echo 	"++ OK -> Found compatible Yarp version!!"																	>> $LOG_FILE 2>&1
		#----------------------------------- iCub-common ----------------------------------------#				
echo   "#----------------------------------- iCub-common ----------------------------------------#"
echo   "#----------------------------------- iCub-common ----------------------------------------#"					>> $LOG_FILE 2>&1

run_in_chroot " mkdir -p /tmp/install_dir/$ICUB_COMMON_NAME/usr"													>> $LOG_FILE 2>&1
run_in_chroot " mkdir -p /tmp/install_dir/$ICUB_COMMON_NAME/DEBIAN"													>> $LOG_FILE 2>&1

if [ $PLATFORM_KEY = "lenny" ] || [ $PLATFORM_KEY = "lucid" ]; then
	# We need to download and compile libode manually and include it
	echo "working on $PLATFORM_KEY, so won't add libode to the dependencies, instead we need to download and compile libode manually and include it"										>> $LOG_FILE 2>&1
# if I'm here the library has already been downloaded
#		run_in_chroot "cd /tmp && wget http://sourceforge.net/projects/opende/files/ODE/0.11.1/ode-0.11.1.zip && echo A | unzip ode-0.11.1.zip >> /dev/null" >> $LOG_FILE 2>&1
# we need to do the configure angain because the path changes
		run_in_chroot "cd /tmp/ode-0.11.1 && ./configure --prefix=/tmp/install_dir/$ICUB_COMMON_NAME/usr --enable-double-precision --enable-shared --disable-drawstuff --disable-demos && make && make install" >> $LOG_FILE 2>&1

else  # if linux version is squeeze or maverick (and newer too, hopefully), libode from synaptic is ok!
	echo "Installing libode-dev"																					>> $LOG_FILE 2>&1
	run_in_chroot "apt-get install $APT_OPTIONS libode-dev"															>> $LOG_FILE 2>&1
	run_in_chroot "apt-get $APT_OPTIONS install -f"																				>> $LOG_FILE 2>&1
	ICUB_DEPENDENCIES="$ICUB_DEPENDENCIES, libode1 (>= 0.11.1), libode-dev"
fi

echo "Building IpOpt libraries for iCub package..."
echo "Building IpOpt libraries for iCub package..."														>> $LOG_FILE 2>&1
if [ ! -e $ICUB_BUILD_CHROOT/tmp/$IPOPT-icub.done ]; then 
	run_in_chroot "cd /tmp/$IPOPT/build; ../configure --prefix=/tmp/install_dir/$ICUB_COMMON_NAME/usr; make install"	>> $LOG_FILE 2>&1
	sudo touch $ICUB_BUILD_CHROOT/tmp/$IPOPT-icub.done														>> $LOG_FILE 2>&1
else
	echo "IpOpt libraries (/icub) already handled."									>> $LOG_FILE 2>&1
fi

SIZE=$(du -s $ICUB_BUILD_CHROOT/tmp/install_dir/$ICUB_COMMON_NAME/)
SIZE=$(echo $SIZE | awk '{ split($0, array, "/" ); print array[1] }')
echo "Size: $SIZE"																									>> $LOG_FILE 2>&1

run_in_chroot "touch /tmp/install_dir/$ICUB_COMMON_NAME/DEBIAN/md5sums"								>> $LOG_FILE 2>&1
cd $ICUB_BUILD_CHROOT/tmp/install_dir/$ICUB_COMMON_NAME/
FILES=$(find -path ./DEBIAN -prune -o -print)
#for FILE in $FILES
#do
#	if [ ! -d $FILE ]; then
#		md5sum $FILE | sudo tee -a $ICUB_BUILD_CHROOT/tmp/install_dir/$ICUB_COMMON_NAME/DEBIAN/md5sums  >> /dev/null
#	fi
#done


# --> Create icub-common package
run_in_chroot " mkdir -p /tmp/install_dir/$ICUB_COMMON_NAME/DEBIAN; touch /tmp/install_dir/$ICUB_COMMON_NAME/DEBIAN/control"	>> $LOG_FILE 2>&1

echo "Generating icub-common package"																				>> $LOG_FILE 2>&1
echo "Package: icub-common
Version: $ICUB_VERSION-$DEBIAN_REVISION_NUMBER
Section: contrib/science
Priority: optional
Architecture: $PLATFORM_HARDWARE
Depends: $ICUB_DEPENDENCIES
Conflicts: coinor-libipopt0, coinor-libipopt-dev
Installed-Size:  $SIZE
Homepage: http://www.robotcub.org, https://projects.coin-or.org/Ipopt
Maintainer: Alberto Cardellino <alberto.cardellino@iit.it>
Description: List of dependencies for iCub software
 This package lists all the dependencies needed to install the icub 
 platform software or to download the source code and compile it directly
 onto your machine. It contains also a compiled version of IpOpt library $EXTENDED_COMMENT" | sudo tee $ICUB_BUILD_CHROOT/tmp/install_dir/$ICUB_COMMON_NAME/DEBIAN/control >> $LOG_FILE 2>&1
 
run_in_chroot "cd /tmp/install_dir; dpkg -b $ICUB_COMMON_NAME $ICUB_COMMON_PKG_NAME.deb"							>> $LOG_FILE 2>&1

# <-- Create icub-common package -end

		#----------------------------------- iCub ----------------------------------------#
echo   "#----------------------------------- iCub ----------------------------------------#"
echo   "#----------------------------------- iCub ----------------------------------------#"						>> $LOG_FILE 2>&1

# Go ahead and configure
run_in_chroot "mkdir -p $D_ICUB_DIR; cd $D_ICUB_DIR; export ICUB_ROOT=$D_ICUB_INSTALL_DIR/usr/share/iCub; $CMAKE -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$D_ICUB_INSTALL_DIR/usr/ -DICUB_USE_SDL=ON -DICUB_USE_ODE=ON -DICUB_SIM_OLD_RESPONDER=ON -DIPOPT_DIR=/usr -DICUB_USE_IPOPT=ON -DICUB_SIM_OMIT_LOGPOLAR=ON -DICUB_USE_GLUT=ON -DICUB_APPLICATIONS_PREFIX=$D_ICUB_INSTALL_DIR/usr/share/iCub -DENABLE_icubmod_DFKI_hand_calibrator=ON -DENABLE_icubmod_canmotioncontrol=ON -DENABLE_icubmod_cartesiancontrollerclient=ON -DENABLE_icubmod_cartesiancontrollerserver=ON -DENABLE_icubmod_debugInterfaceClient=ON -DENABLE_icubmod_fakecan=ON -DENABLE_icubmod_gazecontrollerclient=ON -DENABLE_icubmod_icubarmcalibrator=ON -DENABLE_icubmod_icubarmcalibratorj4=ON -DENABLE_icubmod_icubarmcalibratorj8=ON -DENABLE_icubmod_icubhandcalibrator=ON -DENABLE_icubmod_icubheadcalibrator=ON -DENABLE_icubmod_icubheadcalibratorV2=ON -DENABLE_icubmod_icublegscalibrator=ON -DENABLE_icubmod_icubtorsoonlycalibrator=ON -DENABLE_icubmod_logpolarclient=ON -DENABLE_icubmod_logpolargrabber=ON -DENABLE_icubmod_skinprototype=ON -DENABLE_icubmod_socketcan=ON -D ENABLE_icubmod_static_grabber=ON -D ENABLE_icubmod_xsensmtx=ON  $D_ICUB_ROOT" 													>> $LOG_FILE 2>&1

# Go ahead and make, install and install_applications
run_in_chroot "cd $D_ICUB_DIR; make; make install; make install_applications" 										>> $LOG_FILE 2>&1

SIZE=$(du -s $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/)
SIZE=$(echo $SIZE | awk '{ split($0, array, "/" ); print array[1] }')
echo "Size: $SIZE"

# Generate dpkg DEBIAN folder
run_in_chroot "mkdir -p $D_ICUB_INSTALL_DIR/DEBIAN"																	>> $LOG_FILE 2>&1

# Remove standard ICUB_ROOT.ini file and substitute it with the ad-hoc one.
run_in_chroot "rm $D_ICUB_INSTALL_DIR/usr/share/iCub/ICUB_ROOT.ini"													>> $LOG_FILE 2>&1

#echo "mkdir -p $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/; cp $ICUB_SCRIPT_DIR/ICUB_ROOT.ini $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/"
sudo mkdir -p $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/
sudo cp $ICUB_SCRIPT_DIR/sources/ICUB_ROOT.ini $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/etc/

# Fix path inside cmake files
sudo /$ICUB_SCRIPT_DIR/fix_cmake_path.sh $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR  $ICUB_VERSION_NAME					>> $LOG_FILE 2>&1

# Generate 'conffiles' file
sudo touch $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/conffiles
echo "/etc/ICUB_ROOT.ini" | sudo tee $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/conffiles						>> $LOG_FILE 2>&1

# Generate DEBIAN/md5sums file
if [ -f $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums ]; then
	echo "Removing old md5sums file in $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/"			>> $LOG_FILE 2>&1
	sudo rm $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums							>> $LOG_FILE 2>&1
fi
# Generate dpkg DEBIAN/control file 
run_in_chroot "mkdir -p $D_ICUB_INSTALL_DIR/DEBIAN; touch $D_ICUB_INSTALL_DIR/DEBIAN/control" 						>> $LOG_FILE 2>&1
run_in_chroot "mkdir -p $D_ICUB_INSTALL_DIR/usr/share/doc/icub"
run_in_chroot "cp /tmp/$ICUB_VERSION_NAME/main/COPYING $D_ICUB_INSTALL_DIR/usr/share/doc/icub/copyright"
run_in_chroot "cp /tmp/$ICUB_VERSION_NAME/main/AUTHORS $D_ICUB_INSTALL_DIR/usr/share/doc/icub/AUTHORS"

sudo touch $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums								>> $LOG_FILE 2>&1

#cd $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR
#FILES=$(find -path ./DEBIAN -prune -o -print)
#for FILE in $FILES
#do
#	if [ ! -d $FILE ]; then
#		md5sum $FILE | sudo tee -a $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums  >> /dev/null
#	fi
#done
 
echo "Generating icub package"
echo "Package: icub
Version: $ICUB_VERSION-$DEBIAN_REVISION_NUMBER
Section: contrib/science
Priority: optional
Architecture: $PLATFORM_HARDWARE
Depends: icub-common ( =$ICUB_COMMON_VERSION), yarp ( >= $ICUB_REQYARP_VERSION)
Installed-Size:  $SIZE
Homepage: http://www.robotcub.org
Maintainer: Alberto Cardellino <alberto.cardellino@iit.it>
Description: Software platform for iCub humanoid robot with simulator.
 The iCub is the humanoid robot developed as part of the European project 
 RobotCub and subsequently adopted by more than 20 laboratories worldwide. 
 It has 53 motors that move the head, arms & hands, waist, and legs. It can 
 see and hear, it has the sense of proprioception and movement.
 .
 This package provides the standard iCub software platform and apps to 
 interact with the real iCub robot, or with the included simulator." | sudo tee $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/control
 
# Fix permission for $D_ICUB_INSTALL_DIR/usr/share/iCub folder
run_in_chroot "chown -R 1000:1000 $D_ICUB_INSTALL_DIR/usr/share/iCub"
run_in_chroot "chmod -R g+w $D_ICUB_INSTALL_DIR/usr/share/iCub"

# Build package
run_in_chroot "cd /tmp/install_dir; dpkg -b $ICUB_VERSION_NAME $PACKAGE_NAME"												>> $LOG_FILE 2>&1

echo "Installing package"
run_in_chroot "dpkg -i /tmp/install_dir/$ICUB_COMMON_PKG_NAME.deb" >> $LOG_FILE 2>&1
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

#run_in_chroot "cd /tmp/iCub1.1.7/main/src/libraries/iKin/tutorials/; mkdir -p build; cd build; cmake ..; make; "
run_in_chroot "umount /proc" 			>> $LOG_FILE 2>&1	


## -------------------------  Copying debs elsewhere LOCALLY ---------------------------------- ##

# Copy .debs to somewhere easier to find - shared folder for VM
echo "Copying yarp and iCub debs to shared folder /data/debs/$CHROOT_NAME/ "
mkdir -p /data/debs/$CHROOT_NAME
sudo cp $YARP_PACKAGE_DIR/yarp*.deb /data/debs/$CHROOT_NAME/
sudo cp $ICUB_BUILD_CHROOT/tmp/install_dir/iCub*.deb /data/debs/$CHROOT_NAME/  	
sudo cp $ICUB_BUILD_CHROOT/tmp/install_dir/iCub*.deb /data/debs/$CHROOT_NAME/

## ---------------------------- Test the package with lintian ------------------------------------##
echo -e "\nTesting icub package with lintian."																				>> $LOG_FILE 2>&1
lintian /data/debs/$CHROOT_NAME/$ICUB_COMMON_PKG_NAME.deb > $ICUB_SCRIPT_DIR/log/Lintian-$ICUB_COMMON_PKG_NAME.log					
lintian-info $ICUB_SCRIPT_DIR/log/Lintian-$ICUB_COMMON_PKG_NAME.log > $ICUB_SCRIPT_DIR/log/Lintian-$ICUB_COMMON_NAME.info		 

lintian /data/debs/$CHROOT_NAME/$PACKAGE_NAME > $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.log							 
lintian-info $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.log > $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.info