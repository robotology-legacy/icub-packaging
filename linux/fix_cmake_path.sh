#!/bin/bash
# Building the package using cmake install command, the CMAKE_INSTALL_DIR will appears as prefix of /usr/include folder into .cmake files.
# This script removes the CMAKE_INSTALL_DIR prefix from those files so that the path is correct, so that icub path are corrects and applications can be compiled against icub libraries
# input parameter: 	$1= root folder to search into
#					$2= string to search for

#folder=/data/build/yarp_squeeze_amd64/test_chroot/tmp/install_dir/iCub1.1.6/

_FOLDER=$1
_STRING_TO_REPLACE=$2

if [ ! -d $_FOLDER ]; then
	echo -e "ERROR : path $_FOLDER not found"
	exit 1
fi

files=$(find $_FOLDER -name *.cmake)

for file in $files
do
	echo $file
	# s/A/B/g file_in > file_out ==>> s= substitute string A with B, g= globally (each instance) 
	# in this case substitute  "\/tmp\/install_dir\/$1" with nothing ( //)
	#sed 's/'"\/tmp\/install_dir\/$ICUB_VER"'//g' $file > $file.out
	sed -i "s/$_STRING_TO_REPLACE//g" $file
done

exit 0
