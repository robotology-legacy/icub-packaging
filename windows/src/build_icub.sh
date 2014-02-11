c=$1
v=$2

guard_file=build_icub_${c}_${v}_$3.txt

if [ -e $guard_file ]; then
    echo "Skipping build_icub_${c}_${v}_$3"
    return
fi

echo "Proceeding build_icub_${c}_${v}_$3"
    
	
BUILD_DIR=$PWD

source_dir=iCub$BUNDLE_ICUB_VERSION

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v $3
cd $BUILD_DIR

if [ ! -e $source_dir ]
then
  if [ "$BUNDLE_ICUB_VERSION" == "" ] || [ "$BUNDLE_ICUB_VERSION" == "trunk" ]
  then
			svn co https://github.com/robotology/icub-main/trunk $source_dir || {
				echo "Cannot fetch iCub"
				exit 1
			}
  else
    svn co https://github.com/robotology/icub-main/tags/v${BUNDLE_ICUB_VERSION} $source_dir || {
				echo "Cannot fetch iCub"
				exit 1
			}
  fi
fi  

build_dir=$BUILD_DIR/$source_dir-$OPT_COMPILER-$OPT_VARIANT-$OPT_BUILD

mkdir -p $build_dir
cd $build_dir || exit 1

echo "Using ACE from $ACE_ROOT"
echo "Using YARP from $YARP_DIR"
echo "Using SDL from $SDLDIR"
echo "Using GLUT from $GLUT_DIR"
echo "Using ODE from $ODE_DIR"
echo "Using OpenCV from $OpenCV_DIR"
echo "OPT_GENERATOR: $OPT_GENERATOR"
echo "CMake: $CMAKE_BIN"

ICUB_DIR=`cygpath --mixed "$build_dir/install"`
# cmake uses the following to decide where to install applications
ICUB_ROOT=`cygpath --mixed "$build_dir/install"`
# make it visible to cmake
export ICUB_ROOT 
rm $ICUB_DIR/app -rf 
rm CMakeCache.txt
CMAKE_PARAMETERS=$BUNDLE_CMAKE_PARAMETERS
"$CMAKE_BIN" $CMAKE_PARAMETERS -DCMAKE_INSTALL_PREFIX=$ICUB_DIR -G "$OPT_GENERATOR" ../$source_dir || exit 1

## first call msbuild for target 
## following builds all projects
$OPT_BUILDER iCub.sln /t:Build $OPT_CONFIGURATION_COMMAND $OPT_PLATFORM_COMMAND
# the following install code
"$CMAKE_BIN" --build . --target install --config ${OPT_BUILD} || exit 1

# don't clean obj, since some applications have files with the same extension
# cleanup obj files to save space
# find ./ -type f -name *.obj -exec rm -rf {} \;

# Cache icub paths and variables, for dependent packages to read
ICUB_ROOT=`cygpath --mixed "$BUILD_DIR/$source_dir"`
(
	echo "export ICUB_DIR='$ICUB_DIR'"
	echo "export ICUB_ROOT='$ICUB_ROOT'"
) > $BUILD_DIR/icub_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh

cd $BUILD_DIR

touch $guard_file
