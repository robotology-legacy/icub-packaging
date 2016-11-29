
guard_file="build_opencv_$1_$2_$3.txt"

if [ -e "$guard_file" ]; then
    echo "Skipping build_opencv_$1_$2_$3"
    return
fi

echo "Not found $guard_file"

BUILD_DIR=$PWD

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $1 $2 $3
cd $BUILD_DIR

if [ "BUNDLE_OPENCV_VERSION" == "" ] || [ "BUNDLE_OPENCV_URL" == "" ]; then
  echo "ERROR: Please specify OpenCV version and download URL in the configuration script"
  echo "BUNDLE_OPENCV_VERSION=$BUNDLE_OPENCV_VERSION"
  echo "BUNDLE_OPENCV_URL=$BUNDLE_OPENCV_URL"
  exit 1
fi
ifname="${BUNDLE_OPENCV_URL}/${BUNDLE_OPENCV_VERSION}.zip"
ofname="OpenCV-${BUNDLE_OPENCV_VERSION}.zip"
if [ ! -e $ofname ]; then
  wget $ifname --output-document=${ofname} 
  if [ "$?" != "0" ]; then
    echo "ERROR: Cannot fetch OpenCV from ${ifname}"
    exit 1
  fi
fi

source_dir="opencv-${BUNDLE_OPENCV_VERSION}"
unzip -o $ofname -d ./
build_dir="$BUILD_DIR/$source_dir-$OPT_COMPILER-$OPT_VARIANT-$OPT_BUILD"
OpenCV_DIR=`cygpath --mixed "$build_dir/install"`

if [ ! -d "$build_dir" ]; then
  mkdir $build_dir
fi
cd $build_dir
if [ -f "CMakeCache.txt" ]; then
  rm CMakeCache.txt
fi
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
