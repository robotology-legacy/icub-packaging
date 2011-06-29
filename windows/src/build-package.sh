#!/bin/bash

##############################################################################
#
# Copyright: (C) 2011 RobotCub Consortium
# Authors: Lorenzo Natale
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT
#
# Based on build code for YARP from Paul Fitzpatrick
#
# Amalgamate builds into an NSIS package
# 

# Substitute a given string in a file
# replace_string string_old string_new file
function replace_string {
	string_old=$1
	string_new=$2
	file=$3
	
	echo "Replacing $string_old with $string_new in $file"

    ## we use comma as delimeter so not to confuse sed with / 
	## in strings that contain paths	
	sed -i "s,$string_old,$string_new,g" $file
}

# Add string at specific place inside a file
# replace_string string_old string_new file
function insert_at {
	string=$1
	at=$2
	file=$3

    ## we use comma as delimeter so not to confuse sed with / 
	## in strings that contain paths	
	sed -i "s,^$at,$at\r\n$string," $file
}

# Add string at specific place inside a file
# replace_string string_old string_new file
function insert_top {
	string=$1
	file=$2
	
    ## we use comma as delimeter so not to confuse sed with / 
	## in strings that contain paths	
	sed -i "1i $string" $file
}

BUILD_DIR=$PWD
VENDOR=robotology

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v Release
cd $BUILD_DIR

cd $BUILD_DIR

######### Load env variables for iCub
## load debug variables and save them
source icub_${c}_${v}_Debug.sh
ICUB_DIR_DBG=$ICUB_DIR
ICUB_ROOT_DBG=$ICUB_ROOT
## now load release variables
source icub_${c}_${v}_Release.sh

######### Load env variables for OpenCV
source opencv_${c}_${v}_Debug.sh
OpenCV_DIR_DBG=$OpenCV_DIR
## now load release variables
source opencv_${c}_${v}_Release.sh

######### Start build process
mkdir build-nsis
cd build-nsis

# Get base ICUB path in unix format
ICUB_DIR_DBG_UNIX=`cygpath -u $ICUB_DIR_DBG`
ICUB_DIR_UNIX=`cygpath -u $ICUB_DIR`
SDLDIR_UNIX=`cygpath -u $SDLDIR`
GLUT_DIR_UNIX=`cygpath -u $GLUT_DIR`
OPENCV_DIR_UNIX=`cygpath -u $OpenCV_DIR`
OPENCV_DIR_DBG_UNIX=`cygpath -u $OpenCV_DIR_DBG`
QT3DIR_UNIX=`cygpath -u $QTDIR`

# Make build directory
fname=iCub_package-$BUNDLE_ICUB_VERSION
fname2=$fname
mkdir -p $fname2
cd $fname2 || exit 1
OUT_DIR=$PWD

### Copy some iCub files from debug tree
cp $ICUB_DIR_DBG_UNIX/lib/ICUB/icub-export-install-debug.cmake $ICUB_DIR_UNIX/lib/ICUB
cp $ICUB_DIR_DBG_UNIX/lib/*.lib $ICUB_DIR_UNIX/lib

cd $ICUB_DIR_UNIX/lib/ICUB || exit 1

# backup
cp icub-config.cmake icub-config-fp.cmake
cp icub-export-install-includes.cmake icub-export-install-includes-fp.cmake 
cp icub-export-install-release.cmake icub-export-install-release-fp.cmake
cp icub-export-install-debug.cmake icub-export-install-debug-fp.cmake

#replace_string "$ICUB_DIR" \${ICUB_INSTALLED_LOCATION} icub-config-tmp.cmake

file=icub-config-fp.cmake
replace_string "$ICUB_DIR" \${ICUB_INSTALLED_LOCATION} $file
insert_top "set(ICUB_INSTALLED_LOCATION __NSIS_ICUB_INSTALLED_LOCATION__)" $file

replace_string "$GSL_DIR" \${GSL_INSTALLED_LOCATION} $file
insert_top "set(GSL_INSTALLED_LOCATION __NSIS_GSL_INSTALLED_LOCATION__)"  $file

replace_string "$IPOPT_DIR" \${IPOPT_INSTALLED_LOCATION} $file
insert_top "set(IPOPT_INSTALLED_LOCATION __NSIS_IPOPT_INSTALLED_LOCATION__)"  $file

replace_string "$OpenCV_DIR" \${OPENCV_INSTALLED_LOCATION} $file
insert_top "set(OPENCV_INSTALLED_LOCATION __NSIS_OPENCV_INSTALLED_LOCATION__)" $file


##### fix cmake include file
file=icub-export-install-includes-fp.cmake
replace_string "$ICUB_DIR" \${ICUB_INSTALLED_LOCATION} $file
insert_top "set(ICUB_INSTALLED_LOCATION __NSIS_ICUB_INSTALLED_LOCATION__)" $file
replace_string "$GSL_DIR" \${GSL_INSTALLED_LOCATION} $file
insert_top "set(GSL_INSTALLED_LOCATION __NSIS_GSL_INSTALLED_LOCATION__)" $file
replace_string "$IPOPT_DIR" \${IPOPT_INSTALLED_LOCATION} $file
insert_top "set(IPOPT_INSTALLED_LOCATION __NSIS_IPOPT_INSTALLED_LOCATION__)"  $file
replace_string "$OpenCV_DIR" \${OPENCV_INSTALLED_LOCATION} $file
insert_top "set(OPENCV_INSTALLED_LOCATION __NSIS_OPENCV_INSTALLED_LOCATION__)" $file

##### fix export file
file=icub-export-install-release-fp.cmake
replace_string "$GSL_DIR" \${GSL_INSTALLED_LOCATION} $file
insert_top "set(GSL_INSTALLED_LOCATION __NSIS_GSL_INSTALLED_LOCATION__)" $file
replace_string "$IPOPT_DIR" \${IPOPT_INSTALLED_LOCATION} $file
insert_top "set(IPOPT_INSTALLED_LOCATION __NSIS_IPOPT_INSTALLED_LOCATION__)"  $file
replace_string "$OpenCV_DIR" \${OPENCV_INSTALLED_LOCATION} $file
insert_top "set(OPENCV_INSTALLED_LOCATION __NSIS_OPENCV_INSTALLED_LOCATION__)" $file

file=icub-export-install-debug-fp.cmake
replace_string "$GSL_DIR" \${GSL_INSTALLED_LOCATION} $file
insert_top "set(GSL_INSTALLED_LOCATION __NSIS_GSL_INSTALLED_LOCATION__)" $file
replace_string "$IPOPT_DIR" \${IPOPT_INSTALLED_LOCATION} $file
insert_top "set(IPOPT_INSTALLED_LOCATION __NSIS_IPOPT_INSTALLED_LOCATION__)"  $file
replace_string "$OpenCV_DIR" \${OPENCV_INSTALLED_LOCATION} $file
insert_top "set(OPENCV_INSTALLED_LOCATION __NSIS_OPENCV_INSTALLED_LOCATION__)" $file

# Function to prepare stub files for adding/removing files for an NSIS
# section, and for building the corresponding zip file
function nsis_setup {
	prefix=$1
	echo -n > ${OUT_DIR}/${prefix}_add.nsi
	echo -n > ${OUT_DIR}/${prefix}_remove.nsi
	echo -n > ${OUT_DIR}/${prefix}_zip.sh
}


# Add a file or files into list to be added/removed from NSIS section,
# and to be placed into the corresponding zip file.  Implementation is
# complicated by the need to avoid calling the super-slow cygpath
# command too often.
CYG_BASE=`cygpath -w /`
function nsis_add_base {
	mode=$1
	prefix=$2
	src=$3
	dest=$4
	dir=$5 #optional
	echo "Add " "$@"
	osrc="$src"
	odest="$dest"
	if [ "k$dir" = "k" ] ; then
		src="$PWD/$src"
		osrc="$src"
		src=${src//\//\\}
		src="$CYG_BASE$src"
	else
		src="$dir/$src"
		osrc="$src"
		src=${src//\//\\}
	fi
	dest=${dest//\//\\} # flip to windows convention
	zodest1="zip/$prefix/$zip_name/$odest"
	zodest2="zip_all/$zip_name/$odest"
	if [ "$mode" = "single" ]; then
		dir=`echo $dest | sed 's/\\\\[^\\\\]*$//'`
		echo "CreateDirectory \"\$INSTDIR\\$dir\"" >> $OUT_DIR/${prefix}_add.nsi
		echo "SetOutPath \"\$INSTDIR\"" >> $OUT_DIR/${prefix}_add.nsi
		echo "File /oname=$dest $src" >> $OUT_DIR/${prefix}_add.nsi
		echo "Delete \"\$INSTDIR\\$dest\"" >> $OUT_DIR/${prefix}_remove.nsi
		echo "mkdir -p `dirname $zodest1`" >> $OUT_DIR/${prefix}_zip.sh
		echo "mkdir -p `dirname $zodest2`" >> $OUT_DIR/${prefix}_zip.sh
		echo "cp '$osrc' $zodest1" >> $OUT_DIR/${prefix}_zip.sh
		echo "cp '$osrc' $zodest2" >> $OUT_DIR/${prefix}_zip.sh
	else
		# recursive
		dir=`echo $dest | sed 's/\\\\[^\\\\]*$//'`
		echo "CreateDirectory \"\$INSTDIR\\$dir\"" >> $OUT_DIR/${prefix}_add.nsi
		echo "SetOutPath \"\$INSTDIR\\$dir\"" >> $OUT_DIR/${prefix}_add.nsi
		echo "File /r $src" >> $OUT_DIR/${prefix}_add.nsi
		echo "RmDir /r \"\$INSTDIR\\$dest\"" >> $OUT_DIR/${prefix}_remove.nsi
		echo "mkdir -p $zodest1" >> $OUT_DIR/${prefix}_zip.sh
		echo "mkdir -p $zodest2" >> $OUT_DIR/${prefix}_zip.sh
		echo "cp -r $osrc/* $zodest1" >> $OUT_DIR/${prefix}_zip.sh
		echo "cp -r $osrc/* $zodest2" >> $OUT_DIR/${prefix}_zip.sh
	fi
}

# Add a single file into list to be added/removed from NSIS section,
# and to be placed into the corresponding zip file.
function nsis_add {
	nsis_add_base single "$@"
}

# Add a directory to be added/removed from NSIS section.
function nsis_add_recurse {
	nsis_add_base recurse "$@"
}

# Set up stubs for all NSIS sections
nsis_setup icub_base
nsis_setup icub_headers
nsis_setup icub_libraries
nsis_setup icub_cmake
nsis_setup icub_vc_dlls
nsis_setup icub_sdl_dlls
nsis_setup icub_glut_dlls
nsis_setup icub_qt3_dlls
nsis_setup icub_runtimes
nsis_setup icub_modules
nsis_setup icub_applications

nsis_setup icub_ipopt
nsis_setup icub_opencv
nsis_setup icub_opencv_dlls


ICUB_SUB="icub-$BUNDLE_ICUB_VERSION"
IPOPT_SUB="ipopt-$BUNDLE_IPOPT_VERSION"
OPENCV_SUB="opencv-$BUNDLE_OPENCV_VERSION"

# Add stuff to NSIS

## First license
cd $ICUB_DIR_UNIX || exit 1
ICUB_LICENSE=`cygpath --windows "$ICUB_ROOT/conf/package/copyright.txt"`
ICUB_LOGO=`cygpath --windows "$ICUB_ROOT/conf/package/robotcublogo.bmp"`

## Now cmake files
cd $ICUB_DIR_UNIX/lib/ICUB || exit 1
nsis_add icub_base icub-config-fp.cmake $ICUB_SUB/lib/ICUB/icub-config.cmake
nsis_add icub_base icub-export-install.cmake $ICUB_SUB/lib/ICUB/icub-export-install.cmake
nsis_add icub_base icub-export-install-includes-fp.cmake $ICUB_SUB/lib/ICUB/icub-export-install-includes.cmake
nsis_add icub_base icub-export-install-release-fp.cmake $ICUB_SUB/lib/ICUB/icub-export-install-release.cmake

echo echo "OpenCV Release: $OPENCV_DIR_UNIX"
## add runtime for OpenCV
if [ -e "$OPENCV_DIR_UNIX" ]; then
   cd "$OPENCV_DIR_UNIX/bin" || exit 1
   for f in `ls *.dll`; do
        nsis_add icub_opencv_dlls $f $ICUB_SUB/bin/$f
   done
fi

echo echo "OpenCV Debug: $OPENCV_DIR_DBG_UNIX"
if [ -e "$OPENCV_DIR_DBG_UNIX" ]; then
	cd "$OPENCV_DIR_DBG_UNIX/bin" || exit 1
		for f in `ls *.dll`; do
			nsis_add icub_opencv_dlls $f $ICUB_SUB/bin/$f
	done
fi

cd $ICUB_DIR_UNIX
nsis_add_recurse icub_base share $ICUB_SUB/share

# cd $ICUB_DIR_UNIX/lib || exit 1
# for d in `ls -1 -d --group-directories-first ICUB | head`; do
	# nsis_add_recurse icub_base $d $ICUB_SUB/lib/$d
	# ICUB_LIB_DIR="$d"
	# ICUB_LIB_FILE=`cd $d; ls icub-*.cmake`
# done

## Libraries
cd $ICUB_DIR_UNIX/lib || exit 1
for f in `ls -1 *.lib`; do
	nsis_add icub_libraries $f $ICUB_SUB/lib/$f
done

## Modules
cd $ICUB_DIR_UNIX/bin
for f in `ls -1 *.exe`; do
	nsis_add icub_modules $f $ICUB_SUB/bin/$f
done

## header files
cd $ICUB_DIR_UNIX
nsis_add_recurse icub_headers include $ICUB_SUB/include

## applications
cd $ICUB_DIR_UNIX
nsis_add icub_applications ICUB_ROOT.ini $ICUB_SUB/ICUB_ROOT.ini
nsis_add_recurse icub_applications app $ICUB_SUB/app

## add runtimes for SDL 
if [ -e "$SDLDIR_UNIX" ] ; then
	cd "$SDLDIR_UNIX/lib" || exit 1
	for f in `ls *.dll`; do
		nsis_add icub_sdl_dlls $f $ICUB_SUB/bin/$f
	done
fi

## add runtimes for GLUT 
if [ -e "$GLUT_DIR_UNIX" ] ; then
	cd "$GLUT_DIR_UNIX" || exit 1
	for f in `ls *.dll`; do
		nsis_add icub_glut_dlls $f $ICUB_SUB/bin/$f
	done
fi

## add runtime for QT3
echo "QT3: QT3DIR_UNIX"
if [ -e "$QT3DIR_UNIX" ]; then
   cd "$QT3DIR_UNIX/bin" || exit 1
   for f in `ls *.dll`; do
        nsis_add icub_qt3_dlls $f $ICUB_SUB/bin/$f
	done
fi

# Add Visual Studio redistributable material to NSIS
echo $OPT_VC_REDIST_CRT
if [ -e "$OPT_VC_REDIST_CRT" ] ; then
	cd "$OPT_VC_REDIST_CRT" || exit 1
	for f in `ls *.dll *.manifest`; do
		nsis_add icub_vc_dlls $f $ICUB_SUB/bin/$f "$OPT_VC_REDIST_CRT"
	done
fi

# Add ipopt
cd $IPOPT_DIR
nsis_add_recurse icub_ipopt include $IPOPT_SUB/include
echo "Warning skipping debug version of Ipopt to speed up testing"
nsis_add_recurse icub_ipopt lib/libipopt.lib $IPOPT_SUB/lib/libipopt.lib 
nsis_add_recurse icub_ipopt share $IPOPT_SUB/share

##### Add OpenCV
# Add release stuff
echo $OpenCV_DIR
cd $OpenCV_DIR
nsis_add_recurse icub_opencv 3rdparty $OPENCV_SUB/3rdparty
nsis_add_recurse icub_opencv bin $OPENCV_SUB/bin
nsis_add_recurse icub_opencv doc $OPENCV_SUB/doc
nsis_add_recurse icub_opencv include $OPENCV_SUB/include
nsis_add_recurse icub_opencv lib $OPENCV_SUB/lib

# Add debug stuff
echo $OPENCV_DIR_DBG_UNIX
if [ -e "$OPENCV_DIR_DBG_UNIX" ] ; then
	cd "$OPENCV_DIR_DBG_UNIX/lib" || exit 1
	for f in `ls *.lib`; do
		nsis_add icub_opencv $f $OPENCV_SUB/lib/$f
	done
fi

# Run NSIS
cd $OUT_DIR
echo $OUT_DIR
echo $ICUB_PACKAGE_SOURCE_DIR
cp $ICUB_PACKAGE_SOURCE_DIR/nsis/*.nsh .
$NSIS_BIN -DOPENCV_SUB=$OPENCV_SUB -DIPOPT_SUB=$IPOPT_SUB -DYARP_VERSION=$BUNDLE_YARP_VERSION -DINST2=$ICUB_SUB -DGSL_VERSION=$BUNDLE_GSL_VERSION -DICUB_VERSION=$BUNDLE_ICUB_VERSION -DBUILD_VERSION=${OPT_COMPILER}_${OPT_VARIANT} -DVENDOR=$VENDOR -DICUB_LOGO=$ICUB_LOGO -DICUB_LICENSE=$ICUB_LICENSE -DICUB_ORG_DIR=$ICUB_DIR -DGSL_ORG_DIR=$GSL_DIR -DNSIS_OUTPUT_PATH=`cygpath -w $PWD` `cygpath -m $ICUB_PACKAGE_SOURCE_DIR/nsis/icub_package.nsi` || exit 1

