c=$1
v=$2

guard_file=build_icub_${c}_${v}_$3.txt

if [ -e $guard_file ]; then
    echo "Skipping build_icub_${c}_${v}_$3"
    return
fi

echo "Proceeding build_icub_${c}_${v}_$3"
    
	
BUILD_DIR=$PWD

source_name="icub-main"
source_url="https://github.com/robotology/${source_name}" 
source_dir="${source_name}"

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v $3
cd $BUILD_DIR

if [ ! -e "$source_name" ]; then
  git clone $source_url || {
    echo "Cannot fetch ${source_name} from $source_url"
	exit 1
  }
fi
cd $source_name

if [ "$BUNDLE_ICUB_VERSION" == "" ] || [ "$BUNDLE_ICUB_VERSION" == "trunk" ] || [ "$BUNDLE_ICUB_VERSION" == "master" ]
then
  git checkout master || {
    echo "Cannot fetch master"
	exit 1
  }
  git pull || {
    echo "Cannot update $source_name from $source_url"
	exit 1
  }
else
  git checkout  v${BUNDLE_ICUB_VERSION} || {
    echo "Cannot fetch v${BUNDLE_ICUB_VERSION}"
    exit 1
  }
fi
cd ..
build_dir="${source_name}-${OPT_COMPILER}-${OPT_VARIANT}-${OPT_BUILD}"
echo "Building to ${build_dir}"
if [ -d "$build_dir" ]; then
  rm -rf $build_dir
fi
mkdir -p $build_dir
cd $build_dir

echo "Using ACE from $ACE_ROOT"
echo "Using YARP from $YARP_DIR"
echo "Using SDL from $SDLDIR"
echo "Using GLUT from $GLUT_DIR"
echo "Using ODE from $ODE_DIR"
if [ "$Qt5_DIR" != "" ]; then
  echo "Using Qt5 from $Qt5_DIR"
else
  echo "Skipping QT5"
fi
if [ "$GTKMM_DIR" != "" ]; then
  echo "Using GTKMM from $GTKMM_DIR"
else
  echo "Skipping GTKMM"
fi
echo "Using OpenCV from $OpenCV_DIR"
echo "OPT_GENERATOR: $OPT_GENERATOR"
echo "CMake: $CMAKE_BIN"

ICUB_DIR=`cygpath --mixed "${PWD}/install"`
# cmake uses the following to decide where to install applications
ICUB_ROOT=`cygpath --mixed "${PWD}/install"`
# make it visible to cmake
export ICUB_ROOT 
if [ -d "$ICUB_DIR/app" ]; then
	rm $ICUB_DIR/app -rf 
fi
if [ -f "CMakeCache.txt" ]; then
	rm CMakeCache.txt
fi

"$CMAKE_BIN" -G "$OPT_GENERATOR" -DCMAKE_INSTALL_PREFIX=$ICUB_DIR $BUNDLE_CMAKE_PARAMETERS ../$source_dir || exit 1

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
