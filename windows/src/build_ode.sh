
guard_file="build_ode.txt"

if [ -e $guard_file ]; then
    echo "Skipping build_ode"
    return
fi


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
elif [ "k$c" = "kv8" ]; then
	archivename="ode-0.11.1-bin-msvc8.zip"
	if [ ! -e $archivename ]; then
       wget http://eris.liralab.it/iCub/downloads/packages/windows/msvc8/$archivename
	fi
elif [ "k$c" = "kv9" ]; then
	archivename="ode-0.11.1-bin-msvc9.zip"
	if [ ! -e $archivename ]; then
       wget http://eris.liralab.it/iCub/downloads/packages/windows/msvc9/$archivename
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

touch $guard_file
