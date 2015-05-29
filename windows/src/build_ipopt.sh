
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

IPOPT_VARIANT=""
IPOPT_ARCH=""
case "$c" in
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
case "$v" in
	"x86" )
		IPOPT_ARCH="win32"
		;;
	"x86_64" )
		IPOPT_ARCH="win64"
		;;
	"amd64" )
		IPOPT_ARCH="win64"
		;;
	"*" )
		echo "ERROR: Empty compiler architecture string for IPOPT"
		exit 1
		;;
	"*" )
		echo "ERROR: Usupported compiler architecture for IPOPT: $c"
		exit 1
		;;
esac
packetname="Ipopt-${BUNDLE_IPOPT_VERSION}-${IPOPT_ARCH}-${IPOPT_VARIANT}_mumps+metis+clapack"
archivename="$packetname.zip"
if [ ! -e "$archivename" ]; then
    wget http://www.icub.org/download/packages/windows/${IPOPT_VARIANT}/${archivename}
	if [ "$?" != "0" ]; then
		echo "ERROR: unable to download file $archivename"
		exit -1
	fi
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir
if [ "$?" != "0" ]; then
	echo "ERROR: unable to decompress file $archivename"
	exit -1
fi
rm ./$source_dir/Ipopt-${BUNDLE_IPOPT_VERSION} -rf
mv ./$source_dir/${packetname} ./$source_dir/Ipopt-${BUNDLE_IPOPT_VERSION}

if [ ! -d "$BUILD_DIR/$source_dir/Ipopt-${BUNDLE_IPOPT_VERSION}" ]; then
	echo "ERROR: unable to decompress file $archivename"
	exit -1
fi

# Cache icub paths and variables, for dependent packages to read
IPOPT_DIR=`cygpath --mixed "$BUILD_DIR/$source_dir/Ipopt-${BUNDLE_IPOPT_VERSION}"`
(
	echo "export IPOPT_DIR='$IPOPT_DIR'"
) > $BUILD_DIR/ipopt_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guard_file



