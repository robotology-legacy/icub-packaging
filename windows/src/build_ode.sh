BUILD_DIR=$PWD

source_dir=ode-$c-$v

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v Release
cd $BUILD_DIR

if [ "k$c" = "kv10" ]; then
	archivename="ode-0.11.1-bin-msvc10.zip"
	if [ ! -e $archivename ]; then
       wget http://eris.liralab.it/iCub/downloads/packages/windows/msvc10/$archivename
	fi
else
	echo "Compiler version not yet supported"
	exit -1
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir

# Cache icub paths and variables, for dependent packages to read
ODE_DIR=`cygpath --mixed "$BUILD_DIR/$source_dir/ode-0.11.1"`
(
	echo "export ODE_DIR='$ODE_DIR'"
) > $BUILD_DIR/ode_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR


