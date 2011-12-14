export BUNDLE_ICUB_VERSION=1.1.8
export BUNDLE_ICUB_TWEAK=0
export BUNDLE_IPOPT_VERSION=3.10.1
export BUNDLE_OPENCV_VERSION=2.2.0

export BUNDLE_SDL_VERSION=1.2.13
export BUNDLE_GLUT_VERSION=3.7.6
export BUNDLE_ODE_VERSION=0.11.1
export BUNDLE_ODE_QT3=""

_BUNDLE_YARP_DIR="F:\cygwin\home\icub\yarp2\packaging\windows\build-2-3-14"
export BUNDLE_YARP_DIR=`cygpath $_BUNDLE_YARP_DIR`
export BUNDLE_CMAKE_PARAMETERS="-DENABLE_icubmod_cartesiancontrollerclient:BOOL=TRUE -DENABLE_icubmod_cartesiancontrollerserver:BOOL=TRUE -DENABLE_icubmod_gazecontrollerclient:BOOL=TRUE -DENABLE_icubmod_logpolarclient:BOOL=TRUE -DENABLE_icubmod_logpolarserver:BOOL=TRUE"

 