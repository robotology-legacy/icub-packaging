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

if [ "BUNDLE_SDL_VERSION" == "" ] || [ "BUNDLE_SDL_URL" == "" ]; then
  echo "ERROR: Please specify SDL version and download URL in the configuration script"
  echo "BUNDLE_SDL_VERSION=$BUNDLE_SDL_VERSION"
  echo "BUNDLE_SDL_URL=$BUNDLE_SDL_URL"
  exit 1
fi

SDL_VARIANT=""
SDL_ARCH="$v"
case "$c" in
  "v14" )
    SDL_VARIANT="msvc14"
    ;;
  "v12" )
    SDL_VARIANT="msvc12"
    ;;
  "v11" )
    SDL_VARIANT="msvc11"
    ;;
  "" )
    echo "ERROR: Empty compiler variant string for SDL"
    exit 1
    ;;
  "*" )
    echo "ERROR: Usupported compiler variant for SDL: $c"
    exit 1
    ;;
esac

packetname="SDL-${BUNDLE_SDL_VERSION}_${SDL_VARIANT}" 
archivename="${packetname}.zip"

if [ ! -e $archivename ]; then
  wget ${BUNDLE_SDL_URL}/$archivename 
  if [ "$?" != "0" ]; then
    echo "ERROR: Cannot fetch SDL from ${BUNDLE_SDL_URL}/${archivename}"
    exit 1
  fi
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir
if [ "$?" != "0" ]; then
  echo "ERROR: unable to decompress file $archivename"
  exit -1
fi

# Cache icub paths and variables, for dependent packages to read
SDLDIR=`cygpath --mixed "$BUILD_DIR/$source_dir/${packetname}"`
(
  echo "export SDLDIR='$SDLDIR'"
) > $BUILD_DIR/sdl_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guard_file



