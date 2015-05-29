
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

archivename=""
archive_url=""

if [ "$c" == "v12" ]; then
	archivename="ode-${BUNDLE_ODE_VERSION}-bin-msvc12.zip"
	archive_url="${BUNDLE_ODE_URL}/msvc12"
elif [ "$c" == "v11" ]; then
	archivename="ode-${BUNDLE_ODE_VERSION}-bin-msvc11.zip"
	archive_url="${BUNDLE_ODE_URL}/msvc11"
elif [ "$c" == "v10" ]; then
	archivename="ode-${BUNDLE_ODE_VERSION}-bin-msvc10.zip"
	archive_url="${BUNDLE_ODE_URL}/msvc10"
elif [ "$c" == "v8" ]; then
	archivename="ode-${BUNDLE_ODE_VERSION}-bin-msvc8.zip"
	archive_url="${BUNDLE_ODE_URL}/msvc8"
elif [ "$c" == "v9" ]; then
	archivename="ode-${BUNDLE_ODE_VERSION}-bin-msvc9.zip"
	archive_url="${BUNDLE_ODE_URL}/msvc9"
else
	echo "ERROR: Compiler version $c not supported yet"
	exit 1
fi

if [ ! -e $archivename ]; then
    wget ${archive_url}/${archivename}
	if [ "$?" != "0" ]; then
		echo "ERROR: Cannot fetch ODE from ${archive_url}/${archivename}"
		exit 1
	fi
fi	

mkdir $source_dir
unzip -o $archivename -d ./$source_dir

# Cache icub paths and variables, for dependent packages to read
ODE_DIR=`cygpath --mixed "$BUILD_DIR/$source_dir/ode-0.11.1"`
(
	echo "export ODE_DIR='$ODE_DIR'"
) > $BUILD_DIR/ode_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guard_file