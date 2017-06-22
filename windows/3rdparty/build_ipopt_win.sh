#!/bin/bash -e
# script_template.sh
#set -x
# Defaults
LIBIPOPT_VERSION="3.12.7"
LIBIPOPT_URL="http://www.coin-or.org/download/source/Ipopt/"
#THIRD_PARTY_DEP_LIST="ASL Blas Lapack Metis Mumps"
THIRD_PARTY_DEP_LIST="Blas Lapack Mumps"
FORTRAN_LIBRARIES_LIST_MT="ifconsol.lib libifcoremt.lib libifport.lib libmmt.lib libirc.lib svml_dispmt.lib"
FORTRAN_LIBRARIES_LIST_MD="ifconsol.lib libifcoremd.lib libifportmd.lib libmmd.lib libirc.lib svml_dispmd.lib"
FORTRAN_LIBRARIES_LIST_MTD="ifconsol.lib libifcoremtd.lib libifport.lib libmmtd.lib libirc.lib svml_dispmt.lib"
FORTRAN_LIBRARIES_LIST_MDD="ifconsol.lib libifcoremdd.lib libifportmd.lib libmmdd.lib libirc.lib svml_dispmd.lib"
FORTRAN_DLL_LIST_MD="libifcoremd.dll libmmd.dll"
FORTRAN_DLL_LIST_MDD="libifcoremdd.dll libmmdd.dll"
BUILD_MD="true"
#MSVC_CONFIG_STRING="--enable-msvc"
MSVC_CONFIG_STRING="--enable-doscompile=msvc"
GEN_CONFIG_PARAMS="--disable-linear-solver-loader"
VFORTRANT_PATH_WIN="$IFORT_COMPILER17"
#
LIBIPOPT_NAME="Ipopt-${LIBIPOPT_VERSION}"
LIBIPOPT_PACKAGE="${LIBIPOPT_NAME}.zip"
DATE_BIN="/usr/bin/date"
FIND_BIN="/usr/bin/find"
ARCH=""
VS_VERSION=""
RELEASE_PATH=""
VFORTRANT_LIB_PATH_WIN=""
VFORTRANT_BIN_PATH_WIN=""
FORTRAN_DLL_LIST=""
ACTUAL_PATH=""

print_defs()
{
  echo "Default parameters are"
  echo "  THIRD_PARTY_DEP_LIST is $THIRD_PARTY_DEP_LIST"
  echo "  FORTRAN_LIBRARIES_LIST_MT is $FORTRAN_LIBRARIES_LIST_MT"
  echo "  FORTRAN_LIBRARIES_LIST _MD is $FORTRAN_LIBRARIES_LIST_MD"
  echo "  FORTRAN_LIBRARIES_LIST_MTD is $FORTRAN_LIBRARIES_LIST_MTD"
  echo "  FORTRAN_LIBRARIES_LIST_MDD is $FORTRAN_LIBRARIES_LIST_MDD"
  echo "  FORTRAN_DLL_LIST_MD is $FORTRAN_DLL_LIST_MD"
  echo "  FORTRAN_DLL_LIST_MDD is $FORTRAN_DLL_LIST_MDD"
  echo "  BUILD_MD is $BUILD_MD"
  echo "  MSVC_CONFIG_STRING is $MSVC_CONFIG_STRING"
  echo "  LIBIPOPT_VERSION is $LIBIPOPT_VERSION"
  echo "  LIBIPOPT_URL is $LIBIPOPT_URL"
  echo "  VFORTRANT_PATH_WIN is $VFORTRANT_PATH_WIN"
}

usage()
{
  echo "SCRIPT DESCRIPTION"

  echo "Usage: $0 [options]"
  echo "options are :"
  echo "  -d : print defaults"
  echo "  -h : print this help"
}

log() {
  echo "$(${DATE_BIN} +%d-%m-%Y) - $(${DATE_BIN} +%H:%M:%S) : $1"
}

warn() {
  echo "$(${DATE_BIN} +%d-%m-%Y) - $(${DATE_BIN} +%H:%M:%S) WARNING : $1"
 }

exit_err () {
	echo "$(${DATE_BIN} +%d-%m-%Y) - $(${DATE_BIN} +%H:%M:%S) ERROR : $1"
	exit 1
}


parse_opt() {
  while getopts hd opt
  do
    case "$opt" in
	h)
      usage
      exit 0
      ;;
    d)
      print_defs
      exit 0
      ;;
    \?) # unknown flag
      usage
      exit 1
      ;;
    esac
  done
}

init()
{
 log "$0 STARTED"
 ACTUAL_PATH=$(echo $PATH | sed "s@/usr/local/bin:@@" | sed  "s@/usr/bin:@@")
 VS_VERSION_STRING=$(echo $VisualStudioVersion)
 if [ "$VS_VERSION_STRING" == "" ]; then
   VS_VERSION_STRING=$(echo $TARGET_VS)
 fi
 case "$VS_VERSION_STRING" in
   "10.0" | "vs2010" )
     VS_VERSION="msvc10"
	 ;;
   "11.0" | "vs2012" )
     VS_VERSION="msvc11"
     ;;
   "12.0" | "vs2013")
	  VS_VERSION="msvc12"
	  ;;
   "14.0" | "vs2015")
	  VS_VERSION="msvc14"
	  ;;
   * )
	  exit_err "unsupported or unrecognized Visual Studio Version string $TARGET_VS"
	  ;;
 esac

 if [ "$VFORTRANT_PATH_WIN" == "" ]; then
    exit_err "Invalid (empty?) Visual Fortran string path"
 fi
 case "$TARGET_VS_ARCH" in
	"x86" )
		ARCH="x86"
		VFORTRANT_LIB_PATH_WIN=""${VFORTRANT_PATH_WIN}"\compiler\lib\ia32"
		VFORTRANT_BIN_PATH_WIN=""${VFORTRANT_PATH_WIN}"\redist\ia32\compiler"
		;;
	"x86_64" | "x86_amd64" | "amd64" )
		ARCH="x86_64"
		VFORTRANT_LIB_PATH_WIN=""${VFORTRANT_PATH_WIN}"\compiler\lib\intel64"
		VFORTRANT_BIN_PATH_WIN=""${VFORTRANT_PATH_WIN}"\redist\intel64\compiler"
		;;
	* )
	  exit_err "unsupported or unrecognized target architecture string $TARGET_VS_ARCH"
	  ;;
 esac
 if [ ! -d "$(cygpath -u "${VFORTRANT_LIB_PATH_WIN}")" ]; then
   exit_err "Invalid Fortan libraries path "${VFORTRANT_LIB_PATH_WIN}""
 fi
 if [ ! -d "$(cygpath -u "${VFORTRANT_BIN_PATH_WIN}")" ]; then
   exit_err "Invalid Fortan binaries path "${VFORTRANT_BIN_PATH_WIN}""
 fi
 RELEASE_PATH="ipopt_${LIBIPOPT_VERSION}_${VS_VERSION}_${ARCH}"
 log "BUilding for VisualStudio $VS_VERSION_STRING $ARCH"
 }

fini()
{
  log "$0 ENDED "
}

get_thirdpart()
{
  if [ "$1" == "" ]; then
	  exit_err "invalid Third party path"
  fi
  cd ThirdParty/$1
  if [ ! -f "config.log" ]; then
	./get.$1
  else
    log "$1 skipped,already downloaded"
  fi
  cd ../..
}

get_deps()
{
  for p in $THIRD_PARTY_DEP_LIST
  do
    log "Getting dep $p"
    get_thirdpart $p
  done
}

cleanup()
{
  for d in bin lib share include
  do
    if [ -d "$d" ]; then
	  rm -rf "d"
	fi
  done
  ${FIND_BIN} . -name *.obj -delete
  ${FIND_BIN} . -name *.lo -delete
  ${FIND_BIN} . -name *.la -delete
 }

configure()
{
  log "Configuring LIBIPOPT"

  if [ "$BUILD_MD" == "true" ]; then
    shared_param="--enable-shared"
  fi

  if [ "$1" == "debug" ]; then
    debug_param="--enable-debug"
  fi
  # The configure phase needs the windows path to be prepended
  export PATH="${ACTUAL_PATH}:/usr/local/bin:/usr/bin"
  if [ "$ARCH" == "x86" ]; then
    source /cygdrive/c/Users/icub/Desktop/VS14_2015_intel32_ifort_cygwin_prepend_windows_path.sh
  fi
  if [ "$ARCH" == "x86_64" ]; then
    source /cygdrive/c/Users/icub/Desktop/VS14_2015_intel64_ifort_cygwin_prepend_windows_path.sh
  fi

  ./configure $GEN_CONFIG_PARAMS $MSVC_CONFIG_STRING $shared_param $debug_param
}

build()
{
  log "Building LIBIPOPT"
  export IPOPT_VERSION=
  # The build phase needs the cygwin path to be prepended
  export PATH="/usr/local/bin:/usr/bin:${ACTUAL_PATH}"
  make
  make install
}

copy_deps()
{
  cp lib/*.lib "${RELEASE_PATH}/lib_sources"
  if [ "$1" != "debug" ]; then
    cp -r share "${RELEASE_PATH}/"
    cp -r include "${RELEASE_PATH}/"
    if [ "$BUILD_MD" == "true" ]; then
      TARGET_LIBS="$FORTRAN_LIBRARIES_LIST_MD"
	  FORTRAN_DLL_LIST="$FORTRAN_DLL_LIST_MD"
    else
      TARGET_LIBS="$FORTRAN_LIBRARIES_LIST_MT"
    fi

  else
    if [ "$BUILD_MD" == "true" ]; then
      TARGET_LIBS="$FORTRAN_LIBRARIES_LIST_MDD"
	  FORTRAN_DLL_LIST="$FORTRAN_DLL_LIST_MDD"
    else
      TARGET_LIBS="$FORTRAN_LIBRARIES_LIST_MTD"
    fi
  fi
  for f in $TARGET_LIBS
  do
	cp "$(cygpath -u "${VFORTRANT_LIB_PATH_WIN}")/${f}"  "${RELEASE_PATH}/lib/"
  done

  for f in $FORTRAN_DLL_LIST
  do
    cp "$(cygpath -u "${VFORTRANT_BIN_PATH_WIN}")/${f}" "${RELEASE_PATH}/bin/"
  done
}

create_release_package()
{
  if [ ! -d "$RELEASE_PATH" ]; then
    mkdir "$RELEASE_PATH"
  fi
  if [ ! -d "$RELEASE_PATH/bin" ]; then
    mkdir "${RELEASE_PATH}/bin"
  fi
  if [ ! -d "$RELEASE_PATH/lib" ]; then
    mkdir "${RELEASE_PATH}/lib"
  fi
  if [ -d "${RELEASE_PATH}/lib_sources" ]; then
    rm -rf "${RELEASE_PATH}/lib_sources"
  fi
  mkdir "${RELEASE_PATH}/lib_sources"
  copy_deps  $1
  cd "$RELEASE_PATH\lib_sources"
  if [ "$1" == "debug" ]; then
    lib /out:libipopt_outD.lib *.lib
    mv libipopt_outD.lib ../lib/libipoptD.lib
  else
    lib /out:libipopt_out.lib *.lib
    mv libipopt_out.lib ../lib/libipopt.lib
  fi
  cd ../..
  rm -rf "$RELEASE_PATH\lib_sources"
}

get_ipopt()
{
  if [ ! -f "$LIBIPOPT_PACKAGE" ]; then
    log "Getting file $LIBIPOPT_PACKAGE from $LIBIPOPT_URL"
	wget "${LIBIPOPT_URL}${LIBIPOPT_PACKAGE}"
	if [ "$?" != "0" ]; then
	  exit_err "failed to download ipopt source code"
	fi
  fi
  if [ ! -d "$LIBIPOPT_NAME" ]; then
    unzip $LIBIPOPT_PACKAGE
	if [ "$?" != "0" ]; then
	  exit_err "failed to unzip ipopt source code archive $LIBIPOPT_PACKAGE"
	fi
  fi
}

main()
{
  get_ipopt
  cd "$LIBIPOPT_NAME"
  get_deps
  cleanup
  configure
  build
  create_release_package
  cleanup
  configure debug
  build
  create_release_package debug
}

parse_opt "$@"
init
main
fini
exit 0
