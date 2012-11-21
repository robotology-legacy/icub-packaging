
guard_file="build_opencv_$1_$2_$3.txt"

if [ -e $guard_file ]; then
    echo "Skipping build_opencv_$1_$2_$3"
    return
fi

echo "Not found $guard_file"

BUILD_DIR=$PWD

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $1 $2 $3
cd $BUILD_DIR

#source_dir=OpenCV-2.2.0
#fname=OpenCV-2.4.2-win.zip 
source_dir=opencv
fname=opencv-snapshot-26-09-12.zip 
if [ ! -e $fname ]; then
	#wget http://sourceforge.net/projects/opencvlibrary/files/opencv-win/2.4.2/$fname || (
	wget http://wiki.icub.org/iCub/downloads/packages/windows/common/$fname || (
		echo "Cannot fetch OpenCV"
		exit 1
	)
fi

mkdir $source_dir
unzip -o $fname -d ./

build_dir=$BUILD_DIR/$source_dir-$OPT_COMPILER-$OPT_VARIANT-$OPT_BUILD

OpenCV_DIR=`cygpath --mixed "$build_dir/install"`

mkdir $build_dir
cd $build_dir
rm CMakeCache.txt
"$CMAKE_BIN" -DCMAKE_INSTALL_PREFIX=$OpenCV_DIR -G "$OPT_GENERATOR" ../$source_dir || exit 1
## first call msbuild for target 
# build
$OPT_BUILDER OpenCV.sln /t:Build $OPT_CONFIGURATION_COMMAND $OPT_PLATFORM_COMMAND
# the following install code
"$CMAKE_BIN" --build . --target install --config ${OPT_BUILD} || exit 1

# cleanup obj file to save space
find ./ -type f -name *.obj -exec rm -rf {} \;

# Cache icub paths and variables, for dependent packages to read
OpenCV_DIR=`cygpath --mixed "$build_dir/install"`
(
	echo "export OpenCV_DIR='$OpenCV_DIR'"
) > $BUILD_DIR/opencv_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh


cd $BUILD_DIR

touch $guard_file
