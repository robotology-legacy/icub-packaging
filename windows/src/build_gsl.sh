#!/bin/bash
#set -x
# Check GSL version is set
if [ "$BUNDLE_GSL_VERSION" == "" ]; then
  echo "Set BUNDLE_GSL_VERSION"
  exit 1
fi

if [ "$BUNDLE_GSL_URL" == "" ]; then
  echo "Set BUNDLE_GSL_URL"
  exit 1
fi

BUILD_DIR=$PWD

cd $BUNDLE_YARP_DIR
source  $YARP_BUNDLE_SOURCE_DIR/src/process_options.sh $1 $2 $3
cd $BUILD_DIR

# Go ahead and download GSL source code
fname="gsl-${BUNDLE_GSL_VERSION}"
link="${BUNDLE_GSL_URL}/${fname}.tar.gz"
if [ ! -e $fname ]; then
  if [ ! -e $fname.tar.gz ]; then
    wget $link || {
      echo "Cannot fetch GSL from $link"
      exit 1
    }
  fi
fi

# Unpack source code
if [ ! -e $fname ]; then
  tar xzvf $fname.tar.gz || {
    echo "Cannot unpack GSL"
    exit 1
  }
fi

# Add CMake material for building - easiest way to deal with Windows.
mkdir -p $fname/cmake
cd $fname/cmake || exit 1
if [ ! -e Headers.cmake ] ; then
  # Generate list of parts as Parts.cmake
  find .. -mindepth 2 -iname "Makefile.am" -exec grep -H "_la_SOURCES" {} \; | sed "s|.*/\([-a-z]*\)/Makefile.am|\1 |" | sed "s|:.*=||" | sed "s|^|ADD_PART(|" | sed "s|$|)|" | tee Parts.cmake
  # Generate list of headers as Headers.cmake
  (
  echo "set(GSL_HEADERS"
  echo -n "  "
  find .. -maxdepth 2 -iname "gsl*.h" | sed "s|\.\./||g"
  echo ")"
  ) | tee Headers.cmake
fi

cp "${ICUB_PACKAGE_SOURCE_DIR}/src/gsl/CMakeLists.txt" "$PWD"
cp "${ICUB_PACKAGE_SOURCE_DIR}/src/gsl/msvc_config.h.in" "$PWD/config.h.in" || exit 1
cd $BUILD_DIR

# Make and enter build directory
fname2=${fname}-${c}-${v}-$3
mkdir -p $fname2
cd $fname2 || exit 1

"$CMAKE_BIN" -DGSL_VERSION=$BUNDLE_GSL_VERSION -G "$OPT_GENERATOR" $OPT_CMAKE_OPTION ../$fname/cmake || exit 1

$OPT_BUILDER gsl.sln /t:Build $OPT_CONFIGURATION_COMMAND $OPT_PLATFORM_COMMAND

GSL_DIR=`cygpath --mixed "$PWD"`
GSL_ROOT=`cygpath --mixed "$PWD/../$fname"`


# Request from Lorenzo:
#   Place gsl.lib and gslcblas.lib inside a "lid" directory in the root of the package
#   (i.e. gsl-1.14-v10-x86-Release/lib)

cd $GSL_DIR
mkdir -p lib || exit 1

target_lib_name $OPT_BUILD "gsl" # sets $TARGET_LIB
GSL_LIBRARY="$GSL_DIR/$TARGET_LIB"
cp $GSL_LIBRARY $GSL_DIR/lib || exit 1
GSL_LIBRARY="$GSL_DIR/lib/$TARGET_LIB"

target_lib_name $OPT_BUILD "gslcblas" # sets $TARGET_LIB
GSLCBLAS_LIBRARY="$GSL_DIR/$TARGET_LIB"
cp $GSLCBLAS_LIBRARY $GSL_DIR/lib || exit 1
GSLCBLAS_LIBRARY="$GSL_DIR/lib/$TARGET_LIB"

# Make a GSL ZIP file for Lorenzo
cd $GSL_DIR
(
  echo "GSL version $BUNDLE_GSL_VERSION"
  echo "Downloaded from $link"
  date
  echo " "
  echo "Compiler family: $COMPILER_FAMILY"
  echo "Compiler version: $OPT_COMPILER $OPT_VARIANT $OPT_BUILD"
) > BUILD_INFO.TXT
cd ..
rm -f $fname2.zip
zip -r $fname2.zip $fname2/BUILD_INFO.TXT $fname2/include $fname2/lib || exit 1

# Cache GSL-related paths and variables, for dependent packages to read
(
  echo "export GSL_DIR='$GSL_DIR'"
  echo "export GSL_ROOT='$GSL_ROOT'"
  echo "export GSL_LIBRARY='$GSL_LIBRARY'"
  echo "export GSLCBLAS_LIBRARY='$GSLCBLAS_LIBRARY'"
  echo "export GSL_INCLUDE_DIR='$GSL_DIR/include/'"
) > $BUILD_DIR/gsl_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh
