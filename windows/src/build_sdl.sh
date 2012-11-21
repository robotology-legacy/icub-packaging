guard_file="build_sdl-$c-$v.txt"

if [ -e $guard_file ]; then
    echo "Skipping build_sdl"
    return
fi

BUILD_DIR=$PWD

source_dir=sdl-$c-$v

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v Release
cd $BUILD_DIR

archivename="SDL-1.2.13-bin.zip"
if [ ! -e $archivename ]; then
	wget http://wiki.icub.org/iCub/downloads/packages/windows/common/$archivename
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir

# Cache icub paths and variables, for dependent packages to read
SDLDIR=`cygpath --mixed "$BUILD_DIR/$source_dir/SDL-1.2.13"`
(
	echo "export SDLDIR='$SDLDIR'"
) > $BUILD_DIR/sdl_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guard_file



