
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

if [ "BUNDLE_IPOPT_VERSION" == "" ] || [ "BUNDLE_IPOPT_URL" == "" ]; then
  echo "ERROR: Please specify IPOPT version and download URL in the configuration script"
  echo "BUNDLE_IPOPT_VERSION=$BUNDLE_IPOPT_VERSION"
  echo "BUNDLE_IPOPT_URL=$BUNDLE_IPOPT_URL"
  exit 1
fi

IPOPT_VARIANT=""
IPOPT_ARCH="$v"
case "$c" in
  "v14" )
    IPOPT_VARIANT="msvc14"
    ;;
  "v12" )
    IPOPT_VARIANT="msvc12"
    ;;
  "v11" )
    IPOPT_VARIANT="msvc11"
    ;;
  "v10" )
    IPOPT_VARIANT="msvc10"
    ;;
  "" )
    echo "ERROR: Empty compiler variant string for IPOPT"
    exit 1
    ;;
  "*" )
    echo "ERROR: Usupported compiler variant for IPOPT: $c"
    exit 1
    ;;
esac
packetname="ipopt-${BUNDLE_IPOPT_VERSION}_${IPOPT_VARIANT}_${IPOPT_ARCH}"
archivename="$packetname.zip"
if [ ! -e "$archivename" ]; then
    wget ${BUNDLE_IPOPT_URL}/${archivename}
  if [ "$?" != "0" ]; then
    echo "ERROR: unable to download file $archivename from ${BUNDLE_IPOPT_URL}"
    exit -1
  fi
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir
if [ "$?" != "0" ]; then
  echo "ERROR: unable to decompress file $archivename"
  exit -1
fi


# Cache icub paths and variables, for dependent packages to read
IPOPT_DIR=`cygpath --mixed "$BUILD_DIR/${source_dir}/${packetname}"`
(
  echo "export IPOPT_DIR='$IPOPT_DIR'"
) > $BUILD_DIR/ipopt_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guard_file



