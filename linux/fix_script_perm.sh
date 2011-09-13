#!/bin/bash

# $1 => search folder
folder=$1

OLD_DIR=$PWD

echo "cartella: $folder"
if [ ! -d $folder ]; then
	echo -e "\n\n || ERROR folder doesn't exist!! "
	exit 1
fi

cd $folder
files_py=$(find ./ -name *.py)
files_sh=$(find ./ -name *.sh)

files="$files_py $files_sh"

for file in $files
do
	echo $file
	sudo chmod +x $file
done

cd $OLD_DIR
