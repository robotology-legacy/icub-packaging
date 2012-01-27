guard_file="build_glut-$c-$v.txt"

if [ -e $guard_file ]; then
    echo "Skipping build_glut"
    return
fi


BUILD_DIR=$PWD

source_dir=glut-$c-$v

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $c $v Release
cd $BUILD_DIR

archivename="glut-3.7.6.icub-bin.zip"
if [ ! -e $archivename ]; then
	wget http://eris.liralab.it/iCub/downloads/packages/windows/common/$archivename
fi

mkdir $source_dir
unzip -o $archivename -d ./$source_dir

# Cache icub paths and variables, for dependent packages to read
GLUT_DIR=`cygpath --mixed "$BUILD_DIR/$source_dir/glut-3.7.6-bin"`
(
	echo "export GLUT_DIR='$GLUT_DIR'"
) > $BUILD_DIR/glut_${OPT_COMPILER}_${OPT_VARIANT}_any.sh

cd $BUILD_DIR

touch $guard_file

