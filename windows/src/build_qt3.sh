
guard_file="build_qt3-$c-$v.txt"
if [ -e $guard_file ]; then
    echo "Skipping build_qt3"
    return
fi

BUILD_DIR=$PWD

source_dir=qt3-$c-$v

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v Release
cd $BUILD_DIR

if [ "k$c" = "kv10" ]; then
	archivename="qt3-bin-msvc10.zip"
	if [ ! -e $archivename ]; then
       wget http://eris.liralab.it/iCub/downloads/packages/windows/msvc10/$archivename
	fi
elif [ "k$c" = "kv8" ]; then
	archivename="qt3-bin-0.1-msvc8.zip"
	if [ ! -e $archivename ]; then
       wget http://eris.liralab.it/iCub/downloads/packages/windows/msvc8/$archivename
	fi
elif [ "k$c" = "kv9" ]; then
	archivename="qt3-bin-0.1-msvc9.zip"
	if [ ! -e $archivename ]; then
       wget http://eris.liralab.it/iCub/downloads/packages/windows/msvc9/$archivename
	fi
else
	echo "Compiler version not yet supported"
	exit -1
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir
# make exe files executable
cd $source_dir
find -iname *.exe | xargs chmod u+x

# Cache icub paths and variables, for dependent packages to read
QTDIR=`cygpath --mixed "$BUILD_DIR/$source_dir/qt3"`
(
	echo "export QTDIR='$QTDIR'"
) > $BUILD_DIR/qt3_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guar_dfile


