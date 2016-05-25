#!/bin/bash -e

# For simplicity, make sure this script is not called in-place
if [ -e build.sh ]; then
  echo "Please call from a build directory"
  exit 1
fi

# Set up build and source directory
### store build directory
BUILD_DIR=$PWD
### store previous directory
relative_dir="`dirname $BUILD_DIR`"
cd "$relative_dir"
export ICUB_PACKAGE_SOURCE_DIR=$PWD
cd $BUILD_DIR

BUNDLES="`cd $ICUB_PACKAGE_SOURCE_DIR/conf; ls -1 bundle*.sh | sed "s/\.sh//"`"
if [ "k$1" = "k" ]; then
  echo "Please specify a bundle name.  One of these:"
  # Support tab completion
  for b in $BUNDLES; do
      echo -n " $b"
      echo "$0 $b" > $b
      chmod u+x $b
  done
  echo " "
  exit 1
else
  # Remove tab completion
  for b in $BUNDLES; do
      rm -f $b
  done
fi

# read veersion infos, including BUNDLE_YARP_DIR value
source $ICUB_PACKAGE_SOURCE_DIR/conf/$1.sh

# reads in settings from yarp build
source $BUNDLE_YARP_DIR/settings.sh

YARP_BUNDLE_FILENAME=$SETTINGS_BUNDLE_FILENAME
YARP_BUNDLE_SOURCE_DIR=$SETTINGS_SOURCE_DIR

# reads in versions info from YARP build
if [ ! -f "$YARP_BUNDLE_FILENAME" ]
then
  echo "ERROR: missing yarp bundle filename $YARP_BUNDLE_FILENAME"
  exit 1
fi
source  $YARP_BUNDLE_FILENAME

##### GTKMM for now don't rely on yarp bundle
#ICUB_HOME=`cygpath -m "$HOME"`
#GTK_BASEPATH="$ICUB_HOME/gtkmm-2.22"
#GTKMM_BASEPATH="$ICUB_HOME/gtkmm-2.22"
#export GTKMM_BASEPATH
#export GTK_BASEPATH

# read list of compilers --> $compilers
source $ICUB_PACKAGE_SOURCE_DIR/conf/compilers.sh

# read options from yarp
if [ ! -f "${BUNDLE_YARP_DIR}/nsis_any_any_any.sh" ]
then
  echo "ERROR: missing yarp file ${BUNDLE_YARP_DIR}/nsis_any_any_any.sh"
  exit 1
fi
source ${BUNDLE_YARP_DIR}/nsis_any_any_any.sh
if [ ! -f "${BUNDLE_YARP_DIR}/cmake_any_any_any.sh" ]
then
  echo "ERROR: missing yarp file ${BUNDLE_YARP_DIR}/cmake_any_any_any.sh"
  exit 1
fi
source $BUNDLE_YARP_DIR/cmake_any_any_any.sh

for c in $compilers ; do
  variants=compiler_${c}_variants
    for v in ${!variants}; do
  
    echo "Compiling for $c $v"
  echo $Qt5_DIR

    ########## Release versions
      # we get a series of useful variables
    echo "switching to $BUNDLE_YARP_DIR"
    cd $BUNDLE_YARP_DIR
    # # brings in variables to locate all packages e.g. YARP_DIR, GSL_DIR, ACE_DIR, gtkmm
    source yarp_${c}_${v}_Release.sh
    source gsl_${c}_${v}_Release.sh
    source ace_${c}_${v}_Release.sh
    if [ -f "gtkmm_${c}_${v}_Release.sh" ]; then
      source gtkmm_${c}_${v}_Release.sh
    else
      echo "GTKMM NOT AVAILABLE"
      unset GTKMM_DIR
      unset GTKMM_PATH
      unset GTK_BASEPATH
      unset GTKMM_BASEPATH
    fi
    if [ -f "qt_${c}_${v}_Release.sh" ]; then
      source qt_${c}_${v}_Release.sh
    else
      echo "QT NOT AVAILABLE"
      unset QT_DIR
      unset QT_PATH
      unset Qt5_DIR
    fi
    cd $BUILD_DIR
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_sdl.sh $c $v Release
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_glut.sh $c $v Release
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_ode.sh $c $v Release
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_opencv.sh $c $v Release
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_ipopt.sh $c $v Release
    
    source sdl_${c}_${v}_any.sh
    source glut_${c}_${v}_any.sh
    source ode_${c}_${v}_any.sh
    source ipopt_${c}_${v}_any.sh
    
    source opencv_${c}_${v}_Release.sh
    
    cd $BUILD_DIR
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_icub.sh $c $v Release
      
    ########## Debug versions
    cd $BUNDLE_YARP_DIR
    # # brings in variables to locate all packages e.g. YARP_DIR, GSL_DIR, ACE_DIR, gtkmm
    source yarp_${c}_${v}_Debug.sh
    source gsl_${c}_${v}_Debug.sh
    source ace_${c}_${v}_Debug.sh
    if [ -f "gtkmm_${c}_${v}_Debug.sh" ]; then
      source gtkmm_${c}_${v}_Debug.sh
     else
      echo "GTKMM NOT AVAILABLE"
      unset GTKMM_DIR
      unset GTKMM_PATH
      unset GTK_BASEPATH
      unset GTKMM_BASEPATH
    fi
    if [ -f "qt_${c}_${v}_Debug.sh" ]; then
      source qt_${c}_${v}_Debug.sh
    else
      echo "QT NOT AVAILABLE"
      unset QT_DIR
      unset QT_PATH
      unset Qt5_DIR
    fi
    cd $BUILD_DIR
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_opencv.sh $c $v Debug
    source opencv_${c}_${v}_Debug.sh
    
    cd $BUILD_DIR
    source $ICUB_PACKAGE_SOURCE_DIR/src/build_icub.sh $c $v Debug
    
    cd $BUILD_DIR
    source icub_${c}_${v}_Debug.sh
    source icub_${c}_${v}_Release.sh
    source $ICUB_PACKAGE_SOURCE_DIR/src/build-package.sh $c $v
    
  done
done
#done
