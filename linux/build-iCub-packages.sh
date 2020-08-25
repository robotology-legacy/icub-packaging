#!/bin/bash
# Load everything oeeded from external files
cd "`dirname $0`"
echo $PWD
ICUB_SCRIPT_DIR=$(pwd)
cd $OLDPWD
if [ ! -f "$ICUB_SCRIPT_DIR/prepare.sh" ]; then
 echo "ERROR: missing script $ICUB_SCRIPT_DIR/prepare.sh"
 exit 1
fi
source $ICUB_SCRIPT_DIR/prepare.sh
if [ "$IPOPT" == "Ipopt-3.11.7" ]
then
  IPOPT_BUILD_FLAGS="--enable-dependency-linking"
else
  IPOPT_BUILD_FLAGS=""
fi

#----------------------------------- Debug variables------------------------------------------------#

echo -e "Printing debug information\n"

echo "PACKAGE_VERSION = $PACKAGE_VERSION"
echo "ICUB_DIR = $D_ICUB_DIR"
echo "ICUB_INSTALL_DIR = $D_ICUB_INSTALL_DIR"
echo "Path to yarp is: $YARP_PACKAGE_DIR"
echo "Path to the yarp scripts is $YARP_SCRIPT_DIR"
echo "Path to the yarp builds  is $ICUB_SCRIPT_DIR"
echo -e "$CHROOT_NAME\n"
echo "iCub Sources version = $ICUB_SOURCES_VERSION"
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
	echo "/etc/dchroot.conf $CHROOT_NAME entry already exists."
else
	echo "$CHROOT_NAME $ICUB_BUILD_CHROOT" | sudo tee -a /etc/dchroot.conf
fi

run_in_chroot "mount -t proc proc /proc"
run_in_chroot "DEBIAN_FRONTEND=noninteractive; apt-get install $APT_OPTIONS --install-recommends locales"
run_in_chroot "/usr/sbin/locale-gen en_US en_US.UTF-8"
run_in_chroot "DEBIAN_FRONTEND=noninteractive; apt-get install $APT_OPTIONS apt-transport-https ca-certificates gnupg software-properties-common wget"
run_in_chroot "echo LC_ALL=en_US.UTF-8 >> /etc/environment"
###------------------- Preparing --------------------###

# Check if test_CHROOT_NAME make target has been made
if [ ! -e "$BUILD_DIR/test_${CHROOT_NAME}.txt" ]; then
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

echo "PLATFORM_KEY is $PLATFORM_KEY"
###----------- Handle generic deps -----------------------###
if [ ! -e $ICUB_BUILD_CHROOT/tmp/gen_deps_install.done ]; then
  echo "Installing generic dependencies in the dchroot environment"
  BACKPORTS_URL_TAG="ICUB_DEPS_BACKPORTS_STRING_${PLATFORM_KEY}"
  if [ "${!BACKPORTS_URL_TAG}" != "" ]; then
    run_in_chroot "echo ${!BACKPORTS_URL_TAG} > /etc/apt/sources.list.d/backports.list"
  fi
  run_in_chroot "DEBIAN_FRONTEND=noninteractive; apt-get install $APT_OPTIONS --install-recommends gnupg"
  run_in_chroot "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 57A5ACB6110576A6"
  run_in_chroot "apt-get $APT_OPTIONS update"
  run_in_chroot "apt-get $APT_OPTIONS upgrade"
  run_in_chroot "apt-get $APT_OPTIONS install -f && touch /tmp/gen_deps_install.done"
  if [ ! -e $ICUB_BUILD_CHROOT/tmp/gen_deps_install.done ]; then
    echo "ERROR: problems installing dependancies."
    do_exit 1
  fi 
fi


###------------------- Handle cmake ----------------------###
if [ ! -e "$ICUB_BUILD_CHROOT/tmp/cmake.done" ]; then
  echo "Installing CMAKE in the dchroot environment"
  case "$PLATFORM_KEY" in
    "bionic")
      run_in_chroot "wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add -"
      run_in_chroot "apt-add-repository 'deb https://apt.kitware.com/ubuntu/ $PLATFORM_KEY main'"
      run_in_chroot "DEBIAN_FRONTEND=noninteractive; apt-get install $APT_OPTIONS cmake && touch /tmp/cmake.done" 
      ;;
    "buster")
      run_in_chroot "DEBIAN_FRONTEND=noninteractive; apt-get $APT_OPTIONS -t buster-backports install $APT_OPTIONS cmake && touch /tmp/cmake.done" 
      ;;
    "focal")
      run_in_chroot "DEBIAN_FRONTEND=noninteractive; apt-get install $APT_OPTIONS cmake && touch /tmp/cmake.done" 
      ;; 
    *)
      echo "ERROR: unsupported distro $PLATFORM_KEY"
      do_exit 1
      ;;
  esac 
   if [ ! -e "$ICUB_BUILD_CHROOT/tmp/cmake.done" ]; then
     echo "ERROR: problems installing cmake."
     do_exit 1
   fi
else
  echo "cmake already handled." 
fi 

###------------------- Handle YCM ----------------------###
if [ ! -e "$ICUB_BUILD_CHROOT/tmp/ycm-deb.done" ]; then
  echo "Installing YCM package"
  YCM_URL_TAG="YCM_PACKAGE_URL_${PLATFORM_KEY}"
  run_in_chroot "wget ${!YCM_URL_TAG} -O /tmp/ycm.deb"
  run_in_chroot "DEBIAN_FRONTEND=noninteractive; dpkg -i /tmp/ycm.deb; apt-get install -f; dpkg -i /tmp/ycm.deb && touch /tmp/ycm-deb.done"
  if [ ! -e "$ICUB_BUILD_CHROOT/tmp/ycm-deb.done" ]; then
    echo "ERROR: problem installing YCM"
    do_exit 1
  fi
else
  echo "YCM package already handled."
fi

###----------- Handle iCub deps from icub-common -------###
if [ ! -e $ICUB_BUILD_CHROOT/tmp/icub_deps_install.done ]; then
  echo "Installing icub-common dependencies in the dchroot environment"
  DEP_TAG="ICUB_DEPS_${PLATFORM_KEY}"
  _DEPENDENCIES="$ICUB_DEPS_COMMON ${!DEP_TAG}"
  run_in_chroot "DEBIAN_FRONTEND=noninteractive; apt-get install $APT_OPTIONS $_DEPENDENCIES && touch /tmp/icub_deps_install.done"
  if [ ! -e "$ICUB_BUILD_CHROOT/tmp/icub_deps_install.done" ]; then
    echo "ERROR: problems installing dependancies."
    do_exit 1
  fi 
else
  echo "icub-common deps already handled"
fi

###------------------- Handle IpOpt --------------------###
if [ "$IPOPT" != "" ]
then
  if [ ! -e $ICUB_BUILD_CHROOT/tmp/$IPOPT-usr.done ]; then 
    CURR_DIR=$PWD  #save current folder to get back on track when done
    cd ${ICUB_SCRIPT_DIR}/sources/
    if [ ! -f "${IPOPT}.tar.gz" ] && [ ! -f "${IPOPT}.tar.zip" ]; then
      # download from icub website
      echo "Trying to Download ${IPOPT} from icub website"
      wget http://www.icub.org/download/software/linux/${IPOPT}.tar.gz
      if [ "$?" != "0" ]; then
        echo "Trying to Download ${IPOPT} from main source archive"
        # Download main souce archive
        wget http://www.coin-or.org/download/source/Ipopt/${IPOPT}.zip
        if [ "$?" != "0" ]
        then 
          echo "ERROR unable to Download ${IPOPT}"
          do_exit 1
        fi
      fi
    fi
    if [ -f ${IPOPT}.zip ]; then
      unzip -q -o ${IPOPT}.zip
    elif [ -f ${IPOPT}.tar.gz ]; then
      tar xzf ${IPOPT}.tar.gz
    fi
    if [ "$?" != "0" ]
    then 
     echo "ERROR unable to decompress ${IPOPT}"
     do_exit 1
    fi
    cd $CURR_DIR   # go back
    # Compile and install (twice) the lib IpOpt - components Lapack, Mumps and Metis are already downloaded and placed inside the correct ThirdParty folder
    echo "Usign IpOpt ver $IPOPT"
    if [ ! -d "$ICUB_SCRIPT_DIR/sources/$IPOPT" ]; then
      echo "ERROR: missing IpOpt in path ${ICUB_SCRIPT_DIR}/sources/${IPOPT}"
      do_exit 1
    fi
    sudo cp -rf ${ICUB_SCRIPT_DIR}/sources/${IPOPT}  ${ICUB_BUILD_CHROOT}/tmp/
    if [ "$?" != "0" ]
    then
      echo "ERROR: failed to copy ${ICUB_SCRIPT_DIR}/sources/${IPOPT}"
      do_exit 1
    fi
    THIRD_PARTY="Blas Lapack Metis Mumps"
    for package in $THIRD_PARTY; do
      echo "Getting third party module $package"
      run_in_chroot "cd /tmp/$IPOPT/ThirdParty/${package}; ./get.${package}"
    done	
    run_in_chroot "cd /tmp/$IPOPT/; mkdir -p build; cd build; ../configure $IPOPT_BUILD_FLAGS --prefix=/usr && touch /tmp/${IPOPT}_configure-usr.done"
    if [ ! -f "${ICUB_BUILD_CHROOT}/tmp/${IPOPT}_configure-usr.done" ]
    then
      echo "ERROR: failed to configure ipopt in ${ICUB_BUILD_CHROOT}/tmp/"
      do_exit 1
    fi
    run_in_chroot "cd /tmp/$IPOPT/build && make &&  make test && make install && touch /tmp/${IPOPT}-usr.done"
    if [ ! -f "${ICUB_BUILD_CHROOT}/tmp/${IPOPT}-usr.done" ]
    then															
      echo "ERROR: Build of IpOpt in $ICUB_BUILD_CHROOT/tmp/ failed"
      do_exit 1
    fi
  else
    echo "IpOpt libraries (/usr) already handled." >> $LOG_FILE 2>&1
  fi
fi
# <-- Handle IpOpt - end
#----------------------------------- Download iCub source to correctly resolve iCub-common's dependencies ----------------------------------------#	
#
if [ ! -e $ICUB_BUILD_CHROOT/tmp/icub-${ICUB_SOURCES_VERSION}-sources.done ]; then
  echo    "Getting iCub source"
  if [ "$ICUB_REPO_URL" == "" ]
  then
  	echo "ERROR: missinig ICUB_REPO_URL parameter in config file"
  	exit 1
  fi

  if [ -d "$ICUB_SCRIPT_DIR/sources/icub-main" ]; then
    cd $ICUB_SCRIPT_DIR/sources/icub-main
    echo "Pulling latest version of icub sources from ${ICUB_REPO_URL}"
    git pull --rebase
    if [ "$?" != "0" ]; then
      echo "Error: unable to update icub repositoy from ${ICUB_REPO_URL}"
      exit 1
    fi
  else 
    cd $ICUB_SCRIPT_DIR/sources
    echo "Cloning icub sources from ${ICUB_REPO_URL}"
    git clone $ICUB_REPO_URL
    if [ "$?" != "0" ]; then
      echo "Error: unable to clone icub repositoy from ${ICUB_REPO_URL}"
      exit 1
    fi
    cd icub-main
  fi
  
  if [ "$ICUB_SOURCES_VERSION" == "" ] || [ "$ICUB_SOURCES_VERSION" == "trunk" ]; then
    echo "switch to master branch"
    git checkout master
    if [ "$?" != "0" ]; then
      echo "Error: unable to checkout master branch on icub repository"
      exit 1
    fi
    cd ..
    else
    echo "switch to branch $ICUB_SOURCES_VERSION"
    git checkout $ICUB_SOURCES_VERSION
    if [ "$?" != "0" ]; then
      echo "Error: unable to checkout branch $ICUB_SOURCES_VERSION on icub repository"
      exit 1
    fi
  fi
  	
  if [ ! -d "${ICUB_BUILD_CHROOT}/tmp/icub-main" ]; then
    echo "removing old version of ${ICUB_BUILD_CHROOT}/tmp/icub-main"
    rm -rf "${ICUB_BUILD_CHROOT}/tmp/icub-main"
  fi
  echo "copying iCub-main sources from ${ICUB_SCRIPT_DIR}/sources/icub-main to  ${ICUB_BUILD_CHROOT}/${D_ICUB_ROOT}"
  cp -uR ${ICUB_SCRIPT_DIR}/sources/icub-main ${ICUB_BUILD_CHROOT}/${D_ICUB_ROOT}
  touch ${ICUB_BUILD_CHROOT}/tmp/icub-${ICUB_SOURCES_VERSION}-sources.done
fi  
# Find which version of yarp is required
#echo "${ICUB_BUILD_CHROOT}/${D_ICUB_ROOT}/CMakeLists.txt" 
#echo $(cat "${ICUB_BUILD_CHROOT}/${D_ICUB_ROOT}/CMakeLists.txt" | grep "find_package(YARP")
ICUB_REQYARP_VERSION=$(cat "${ICUB_BUILD_CHROOT}/${D_ICUB_ROOT}/CMakeLists.txt" | grep "set(YARP_REQUIRED_VERSION" | awk '{print $2}' | tr -d '()')
#YARP_VERSION_STRING=$(cat "${ICUB_BUILD_CHROOT}/${D_ICUB_ROOT}/CMakeLists.txt" | grep ICUB_REQYARP_VERSION)
if [ "$ICUB_REQYARP_VERSION" == "" ]
then
	echo "ERROR: Required Yarp version string not found in ${ICUB_BUILD_CHROOT}/${D_ICUB_ROOT}/CMakeLists.txt"
	exit 1
else
  echo "Required YARP version is $ICUB_REQYARP_VERSION"
fi
#TMP=$(echo $YARP_VERSION_STRING | awk '{ split($0, array, "MAJOR" ); print array[2] }')
#echo $TMP
#ICUB_REQYARP_VERSION_MAJOR=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')
#echo "Major $ICUB_REQYARP_VERSION_MAJOR"
#TMP=$(echo $YARP_VERSION_STRING | awk '{ split($0, array, "MINOR" ); print array[2] }')
#echo $TMP
#ICUB_REQYARP_VERSION_MINOR=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')
#echo "Minor $ICUB_REQYARP_VERSION_MINOR"
#TMP=$(echo $YARP_VERSION_STRING | awk '{ split($0, array, "PATCH" ); print array[2] }')
#echo $TMP
#ICUB_REQYARP_VERSION_PATCH=$(echo $TMP | awk '{ split($0, array, "\"" ); print array[2] }')
#echo "Patch $ICUB_REQYARP_VERSION_PATCH"
#ICUB_REQYARP_VERSION="${ICUB_REQYARP_VERSION_MAJOR}.${ICUB_REQYARP_VERSION_MINOR}.${ICUB_REQYARP_VERSION_PATCH}"
#if [ "$ICUB_REQYARP_VERSION_MAJOR" == "" ] || [ "$ICUB_REQYARP_VERSION_MINOR" == "" ] || [ "$ICUB_REQYARP_VERSION_PATCH" == "" ] || [ "$ICUB_REQYARP_VERSION" == "" ]; then
#  echo "ERROR: unable to retrive YARP version (string is $YARP_VERSION_STRING)"
#  exit 1
#else
#  echo "Required YARP version is $ICUB_REQYARP_VERSION"
#fi
case  "${PLATFORM_HARDWARE}" in
"amd64" ) 
  PLAT_TAG="x86_64"
  ;;
"i386" )
  PLAT_TAG="i386"
  ;;
* )
  echo "ERROR: unsupported PLATFORM_HARDWARE : $PLATFORM_HARDWARE"
  exit 1
  ;;
esac
echo "${YARP_TEST_CHROOT}/usr/lib/${PLAT_TAG}-linux-gnu/cmake/YARP/YARPConfig.cmake"
YARP_VERSION_MAJOR=$(grep YARP_VERSION_MAJOR ${YARP_TEST_CHROOT}/usr/lib/${PLAT_TAG}-linux-gnu/cmake/YARP/YARPConfig.cmake | awk '{print $2}' | tr -d '"' | tr -d ')')
YARP_VERSION_MINOR=$(grep YARP_VERSION_MINOR ${YARP_TEST_CHROOT}/usr/lib/${PLAT_TAG}-linux-gnu/cmake/YARP/YARPConfig.cmake | awk '{print $2}' | tr -d '"' | tr -d ')')
YARP_VERSION_PATCH=$(grep YARP_VERSION_PATCH ${YARP_TEST_CHROOT}/usr/lib/${PLAT_TAG}-linux-gnu/cmake/YARP/YARPConfig.cmake | awk '{print $2}' | tr -d '"' | tr -d ')')
YARP_VERSION="${YARP_VERSION_MAJOR}.${YARP_VERSION_MINOR}.${YARP_VERSION_PATCH}"
if [ "$YARP_VERSION_MAJOR" == "" ] || [ "$YARP_VERSION_MINOR" == "" ] || [ "$YARP_VERSION_PATCH" == "" ] || [ "$YARP_VERSION" == "" ]; then
  echo "ERROR: unable to retrive YARP version (string is $YARP_VERSION)"
  exit 1
else
  echo "Found Yarp version $YARP_VERSION"
fi
if [ "${YARP_VERSION}" == "trunk" ]; then
  if [ "${ICUB_SOURCES_VERSION}" != "trunk" ]; then
    echo "ERROR: both yarp and icub sources must be trunk, found YARP=$YARP_VERSION and iCub=${ICUB_SOURCES_VERSION}"
  fi
fi
#----------------------------------- iCub-common ----------------------------------------#				
if [ ! -e "$ICUB_BUILD_CHROOT/tmp/icub-common-deb.done" ]; then
  echo "Installing icub-common package"
  ICUB_COMMON_URL_TAG="ICUB_COMMON_PACKAGE_URL_${PLATFORM_KEY}"
  run_in_chroot "wget ${!ICUB_COMMON_URL_TAG} -O /tmp/icub-common.deb"
  run_in_chroot "DEBIAN_FRONTEND=noninteractive; dpkg -i /tmp/icub-common.deb; apt-get install -f; dpkg -i /tmp/icub-common.deb && touch /tmp/icub-common-deb.done"
  if [ ! -e "$ICUB_BUILD_CHROOT/tmp/icub-common-deb.done" ]; then
    echo "ERROR: problem installing icub-common"
    do_exit 1
  fi
else
  echo "icub-common package already handled."
fi
#----------------------------------- iCub ----------------------------------------#
if [ ! -e ${ICUB_BUILD_CHROOT}/tmp/iCub-package.done ]; then
  # Go ahead and configure
  run_in_chroot "mkdir -p $D_ICUB_DIR"
  if [ ! -d "${ICUB_BUILD_CHROOT}/${D_ICUB_DIR}" ]
  then
  	echo "ERROR: Build of iCub package in ${ICUB_BUILD_CHROOT}/${D_ICUB_DIR} failed, unable to create dir ${ICUB_BUILD_CHROOT}/${D_ICUB_DIR}"
  	exit 1
  fi
  if [ -f "${ICUB_BUILD_CHROOT}/tmp/configure-icub-package.done" ]; then
    rm "${ICUB_BUILD_CHROOT}/tmp/configure-icub-package.done"
  fi
  CMAKE_OPTIONS_TAG="CMAKE_OPTIONS_${PLATFORM_KEY}"
  _SPECIAL_DIST_CMAKE_OPTIONS="${!CMAKE_OPTIONS_TAG}"
  run_in_chroot "cd $D_ICUB_DIR ; export ICUB_ROOT=$D_ICUB_INSTALL_DIR/usr/share/iCub; $CMAKE $ICUB_CMAKE_OPTIONS -DCMAKE_INSTALL_PREFIX=$D_ICUB_INSTALL_DIR/usr/ -DICUB_APPLICATIONS_PREFIX=$D_ICUB_INSTALL_DIR/usr/share/iCub  $_SPECIAL_DIST_CMAKE_OPTIONS $D_ICUB_ROOT && touch /tmp/configure-icub-package.done"
  if [ ! -f "${ICUB_BUILD_CHROOT}/tmp/configure-icub-package.done" ]
  then
    echo "ERROR: cmake of iCub package in ${ICUB_BUILD_CHROOT}/${D_ICUB_DIR} failed"
    exit 1
  fi
  # Go ahead and make, install
  if [ -f "${ICUB_BUILD_CHROOT}/tmp/build-icub-package.done" ]; then
    rm "${ICUB_BUILD_CHROOT}/tmp/build-icub-package.done"
  fi

  run_in_chroot "cd $D_ICUB_DIR && make -j && make install && touch /tmp/build-icub-package.done"
  #run_in_chroot "export DESTDIR=$D_ICUB_INSTALL_DIR; cd $D_ICUB_DIR && make && make install && touch /tmp/build-icub-package.done"
  if [ ! -f "${ICUB_BUILD_CHROOT}/tmp/build-icub-package.done" ]
  then
    echo "ERROR: Build of iCub package  in ${ICUB_BUILD_CHROOT}/${D_ICUB_DIR} failed"
    exit 1
  fi
  if [ -f "${ICUB_BUILD_CHROOT}/tmp/build-deb-icub-package.done" ]; then
    rm ${ICUB_BUILD_CHROOT}/tmp/build-deb-icub-package.done
  fi

  SIZE=$(du -s $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/)
  SIZE=$(echo $SIZE | awk '{ split($0, array, "/" ); print array[1] }')
  echo "Size: $SIZE"
  
  # Generate dpkg DEBIAN folder
  run_in_chroot "mkdir -p ${D_ICUB_INSTALL_DIR}/DEBIAN"
  
  ICUB_INI_PATH="$ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/usr/share/yarp/config/path.d"
  ICUB_INI_FILE="iCub.ini"
  
  # this fixes missing iCub.ini file
  if [ ! -e "${ICUB_INI_PATH}/${ICUB_INI_FILE}" ]
  then
    mkdir -p $ICUB_INI_PATH
    touch ${ICUB_INI_PATH}/${ICUB_INI_FILE}
    echo ###### This file is automatically generated by CMake. >> ${ICUB_INI_PATH}/${ICUB_INI_FILE}
    echo [search iCub] >> ${ICUB_INI_PATH}/${ICUB_INI_FILE}
    echo path "/usr/share/iCub">> ${ICUB_INI_PATH}/${ICUB_INI_FILE}
  fi
  
  # Fix path inside cmake files
  #sudo /$ICUB_SCRIPT_DIR/fix_cmake_path.sh $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR $D_ICUB_INSTALL_DIR
  _cmake_files=$(find ${ICUB_BUILD_CHROOT}/${D_ICUB_INSTALL_DIR} -name *.cmake)
  for f in $_cmake_files ; do
    sed -i "s|$D_ICUB_INSTALL_DIR||g" $f
  done

  # Fix path inside  ini files
  _ini_files=$(find ${ICUB_BUILD_CHROOT}/${D_ICUB_INSTALL_DIR} -name *.ini)
  for f in $_ini_files ; do
    sed -i "s|$D_ICUB_INSTALL_DIR||g" $f
  done
  
  # Generate 'conffiles' file
  run_in_chroot "touch ${D_ICUB_INSTALL_DIR}/DEBIAN/conffiles"
  
  # Generate DEBIAN/md5sums file
  if [ -f $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums ]; then
  	echo "Removing old md5sums file in $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/"
  	sudo rm $ICUB_BUILD_CHROOT/$D_ICUB_INSTALL_DIR/DEBIAN/md5sums
  fi
  # Generate dpkg DEBIAN/control file 
  run_in_chroot "touch ${D_ICUB_INSTALL_DIR}/DEBIAN/control"
  run_in_chroot "mkdir -p ${D_ICUB_INSTALL_DIR}/usr/share/doc/icub"
  run_in_chroot "cp ${D_ICUB_ROOT}/COPYING ${D_ICUB_INSTALL_DIR}/usr/share/doc/icub/copyright"
  run_in_chroot "cp ${D_ICUB_ROOT}/AUTHORS ${D_ICUB_INSTALL_DIR}/usr/share/doc/icub/AUTHORS"
  run_in_chroot "touch ${D_ICUB_INSTALL_DIR}/DEBIAN/md5sums"
  
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
Version: ${PACKAGE_VERSION}-${DEBIAN_REVISION_NUMBER}~${PLATFORM_KEY}
Section: contrib/science
Priority: optional
Architecture: ${PLATFORM_HARDWARE}
Depends: icub-common (= ${ICUB_COMMON_VERSION}~${PLATFORM_KEY}), yarp (>= ${ICUB_REQYARP_VERSION})
Installed-Size:  $SIZE
Homepage: http://www.icub.org
Maintainer: ${ICUB_PACKAGE_MAINTAINER}
Description: Software platform for iCub humanoid robot with simulator.
 The iCub is the humanoid robot developed as part of the European project 
 RobotCub and subsequently adopted by more than 20 laboratories worldwide. 
 It has 53 motors that move the head, arms & hands, waist, and legs. It can 
 see and hear, it has the sense of proprioception and movement.
 .
 This package provides the standard iCub software platform and apps to 
 interact with the real iCub robot, or with the included simulator." | sudo tee ${ICUB_BUILD_CHROOT}/${D_ICUB_INSTALL_DIR}/DEBIAN/control
   
  # Fix permission for $D_ICUB_INSTALL_DIR/usr/share/iCub folder
  run_in_chroot "chown -R 1000:1000 $D_ICUB_INSTALL_DIR/usr/share/iCub"
  run_in_chroot "chmod -R g+w $D_ICUB_INSTALL_DIR/usr/share/iCub"
  
  # Build package
  if [ -f "${ICUB_BUILD_CHROOT}/tmp/build-deb-icub-package.done" ]; then
    rm "${ICUB_BUILD_CHROOT}/tmp/build-deb-icub-package.done"
  fi
  run_in_chroot "cd /tmp/install_dir && dpkg -b ${D_ICUB_INSTALL_DIR} $PACKAGE_NAME && touch /tmp/build-deb-icub-package.done"
  if [ ! -f "${ICUB_BUILD_CHROOT}/tmp/build-deb-icub-package.done" ]; then
    echo "ERROR: cmake of iCub package in ${ICUB_BUILD_CHROOT}/${D_ICUB_DIR} failed"
    exit 1
  fi
  echo "Installing package $PACKAGE_NAME"
  run_in_chroot "dpkg -i /tmp/install_dir/$PACKAGE_NAME && touch /tmp/iCub-package.done"
  if [ ! -f "${ICUB_BUILD_CHROOT}/tmp/iCub-package.done" ]; then
    echo "ERROR: installing iCub package ${ICUB_BUILD_CHROOT}/tmp/install_dir/${PACKAGE_NAME} failed"
    exit 1
  fi
else
  echo "iCub package already handled"
fi
run_in_chroot "umount /proc"


## -------------------------  Copying debs elsewhere LOCALLY ---------------------------------- ##

# Copy .debs to somewhere easier to find - shared folder for VM
echo "Copying yarp and iCub debs to shared folder /data/debs/$CHROOT_NAME/ "
mkdir -p /data/debs/$CHROOT_NAME
sudo cp $YARP_PACKAGE_DIR/yarp*.deb /data/debs/$CHROOT_NAME/
sudo cp $ICUB_BUILD_CHROOT/tmp/install_dir/iCub*.deb /data/debs/$CHROOT_NAME/  	

if [ "$SKIP_TESTS" != "true" ]; then
## ---------------------------- Test the packages with lintian ------------------------------------##
  if [ -e "/data/debs/$CHROOT_NAME/$ICUB_COMMON_PKG_NAME.deb" ]; then
    echo -e "\nTesting icub-common package with lintian."
    lintian /data/debs/$CHROOT_NAME/$ICUB_COMMON_PKG_NAME.deb > $ICUB_SCRIPT_DIR/log/Lintian-$ICUB_COMMON_PKG_NAME.log					
    lintian-info $ICUB_SCRIPT_DIR/log/Lintian-$ICUB_COMMON_PKG_NAME.log > $ICUB_SCRIPT_DIR/log/Lintian-$ICUB_COMMON_NAME.info
  else
    echo "ERROR: icub-common package file /data/debs/$CHROOT_NAME/$ICUB_COMMON_PKG_NAME.deb not found, exiting"
    exit 1
  fi
  if [ -e "/data/debs/$CHROOT_NAME/$PACKAGE_NAME" ]; then
    echo -e "\nTesting iCub package with lintian."
    lintian /data/debs/$CHROOT_NAME/$PACKAGE_NAME > $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.log							 
    lintian-info $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.log > $ICUB_SCRIPT_DIR/log/Lintian-${PACKAGE_NAME}.info
  else
    echo "ERROR: icub package file /data/debs/$CHROOT_NAME/${PACKAGE_NAME} not found, exiting"
    exit 1
  fi
fi
