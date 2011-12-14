BUILD_DIR=$PWD

source_dir=OpenCV-2.2.0

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v $1
cd $BUILD_DIR

fname=OpenCV-2.2.0-win.zip 
if [ ! -e $fname ]; then
	wget http://sourceforge.net/projects/opencvlibrary/files/opencv-win/2.2/$fname || (
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

rsynch 
cd $BUILD_DIR


