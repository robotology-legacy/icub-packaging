
guard_file="build_ode-$c-$v.txt"

if [ -e $guard_file ]; then
    echo "Skipping build_ode"
    return
fi


BUILD_DIR=$PWD

source_dir=ode-$c-$v

#cd $BUNDLE_YARP_DIR
#source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v Release
cd $BUILD_DIR

if [ "BUNDLE_ODE_VERSION" == "" ] || [ "BUNDLE_ODE_URL" == "" ]; then
  echo "ERROR: Please specify ODE version and download URL in the configuration script"
  echo "BUNDLE_ODE_VERSION=$BUNDLE_ODE_VERSION"
  echo "BUNDLE_ODE_URL=$BUNDLE_ODE_URL"
  exit 1
fi

ODE_VARIANT=""
ODE_ARCH="$v"
case "$c" in
  "v14" )
    ODE_VARIANT="msvc14"
    ;;
  "v12" )
    ODE_VARIANT="msvc12"
    ;;
  "v11" )
    ODE_VARIANT="msvc11"
    ;;
  "v10" )
    ODE_VARIANT="msvc10"
    ;;
  "" )
    echo "ERROR: Empty compiler variant string for ODE"
    exit 1
    ;;
  "*" )
    echo "ERROR: Usupported compiler variant for ODE: $c"
    exit 1
    ;;
esac
packetname="ode-${BUNDLE_ODE_VERSION}_${ODE_VARIANT}_${ODE_ARCH}"
archivename="$packetname.zip"
if [ ! -e "$archivename" ]; then
    wget ${BUNDLE_ODE_URL}/${archivename}
  if [ "$?" != "0" ]; then
    echo "ERROR: unable to download file $archivename from ${BUNDLE_ODE_URL}"
    exit -1
  fi
fi


mkdir $source_dir
unzip -o $archivename -d ./$source_dir

# Cache icub paths and variables, for dependent packages to read
ODE_DIR=`cygpath --mixed "$BUILD_DIR/$source_dir/${packetname}"`
(
  echo "export ODE_DIR='$ODE_DIR'"
) > $BUILD_DIR/ode_${c}_${v}_any.sh

cd $BUILD_DIR

touch $guard_file