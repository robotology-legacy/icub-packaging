
guard_file="build_ipopt-$c-$v.txt"

if [ -e $guard_file ]; then
    echo "Skipping build_ipopt"
    return
fi


BUILD_DIR=$PWD

source_dir=ipopt-$c-$v

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v Release
cd $BUILD_DIR

if [ "k$c" = "kv11" ]; then
	packetname="Ipopt-3.10.1-win32-msvc11_mumps+metis+clapack"
	archivename="$packetname.zip"
	if [ ! -e $archivename ]; then
       wget http://wiki.icub.org/iCub/downloads/packages/windows/msvc11/$archivename
	fi
elif [ "k$c" = "kv10" ]; then
	packetname="Ipopt-3.10.1-win32-msvc10_mumps+metis+clapack"
	archivename="$packetname.zip"
	if [ ! -e $archivename ]; then
       wget http://wiki.icub.org/iCub/downloads/packages/windows/msvc10/$archivename
	fi
elif [ "k$c" = "kv8" ]; then
	packetname="Ipopt-3.10.1-win32-msvc8_mumps+metis+clapack"
	archivename="$packetname.zip"
	if [ ! -e $archivename ]; then
       wget http://wiki.icub.org/iCub/downloads/packages/windows/msvc8/$archivename
	fi
elif [ "k$c" = "kv9" ]; then
	packetname="Ipopt-3.10.1-win32-msvc9_mumps+metis+clapack"
	archivename="$packetname.zip"
	if [ ! -e $archivename ]; then
       wget http://wiki.icub.org/iCub/downloads/packages/windows/msvc9/$archivename
	fi	
else
	echo "Compiler version not yet supported"
	exit -1
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir
rm ./$source_dir/Ipopt-3.7.10.1 -rf
mv ./$source_dir/${packetname} ./$source_dir/Ipopt-3.7.10.1 

# Cache icub paths and variables, for dependent packages to read
IPOPT_DIR=`cygpath --mixed "$BUILD_DIR/$source_dir/Ipopt-3.7.10.1"`
(
	echo "export IPOPT_DIR='$IPOPT_DIR'"
) > $BUILD_DIR/ipopt_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guard_file



