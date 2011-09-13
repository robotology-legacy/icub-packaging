#!/bin/bash
# Building the package using cmake install command, the CMAKE_INSTALL_DIR will appears as prefix of /usr/include folder into .cmake files.
# This script removes the CMAKE_INSTALL_DIR prefix from those files so that the path is correct, so that icub path are corrects and applications can be compiled against icub libraries
# input parameter: 	$1= root folder to search into
#					$2= string to search for

#folder=/data/build/yarp_squeeze_amd64/test_chroot/tmp/install_dir/iCub1.1.6/

OLD_DIR=$PWD
FOLDER=$1
ICUB_VER=$2

echo "cartella: $FOLDER"
if [ ! -d $FOLDER ]; then
	echo -e "\n\n || ERROR cartella non esiste!! "
	exit 1
fi

cd $FOLDER	
files=$(find ./ -name *.cmake)

for file in $files
do
	echo $file
	# s/A/B/g file_in > file_out ==>> s= substitute string A with B, g= globally (each instance) 
	# in ths case substitute  "\/tmp\/install_dir\/$1" with nothing ( //)
	sed 's/'"\/tmp\/install_dir\/$ICUB_VER"'//g' $file > $file.out
	rm $file
	mv $file.out $file
done

cd $OLD_DIR
