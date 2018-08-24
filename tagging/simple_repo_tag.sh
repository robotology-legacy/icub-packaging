#!/bin/bash -e
# simple_tag.sh
#set -x
# Defaults
COMMIT_MESSAGE_HEAD="iCub Software release"
STABLE_VERSION="1.10.1"
FEATURE_VERSION="1.12.0"
GIT_USER_NAME="Matteo"
GIT_USER_SURNAME="Brunettini"
SET_GIT_USER="true"
REMOTE_UPDATE="true"
#

print_defs ()
{
  echo "Default parameters are"
  echo "   is $"
}

usage ()
{
  echo "SCRIPT DESCRIPTION"

  echo "Usage: $0 [options]"
  echo "options are :"

  echo "  -d : print defaults"
  echo "  -h : print this help"
}

log() {
  echo -e "\e[96m$(date +%d-%m-%Y) - $(date +%H:%M:%S) : $1\e[39m"
}

warn() {
  echo -e "e[33m$(date +%d-%m-%Y) - $(date +%H:%M:%S) WARNING : $1\e[39m"
 }

error() {
  echo -e "\e[31m$(date +%d-%m-%Y) - $(date +%H:%M:%S) ERROR : $1\e[39m"
}

exit_err () {
        error "$1"
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
}

fini()
{
  log "$0 ENDED "
}

set_git_user() {
  git config --local user.email "${GIT_USER_NAME}.${GIT_USER_SURNAME}@iit.it"
  git config --local user.name "${GIT_USER_NAME} ${GIT_USER_SURNAME}"
}

check_tags() {
  if ! x=$(git rev-parse v$STABLE_VERSION >/dev/null 2>&1); then _STABLE_EXISTS="false"; else _STABLE_EXISTS="true"; fi
  if ! x=$(git rev-parse v$FEATURE_VERSION >/dev/null 2>&1); then _FEATURE_EXISTS="false"; else _FEATURE_EXISTS="true"; fi

  if [ "$_STABLE_EXISTS" == "true" ]; then
    git tag -d v$STABLE_VERSION
  fi

  if [ "$_FEATURE_EXISTS" == "true" ]; then
    git tag -d v$FEATURE_VERSION
  fi
}

main()
{
  if [ "$SET_GIT_USER" == "true" ]; then
    set_git_user
  fi

  check_tags

  git fetch --all --prune
  _GIT_DEVEL_BRANCH=$(git branch -a | grep "origin/devel") || true
  if [ "$_GIT_DEVEL_BRANCH" == "" ]; then
    _DEVEL_EXISTS="false"
  else
    _DEVEL_EXISTS="true"
  fi
  if [ "$_DEVEL_EXISTS" == "true" ]; then
    git checkout -f devel
    git reset --hard origin/devel
  fi
  git checkout -f master
  git reset --hard origin/master
  git tag -a -m "${COMMIT_MESSAGE_HEAD} ${STABLE_VERSION}" v${STABLE_VERSION}
  if [ "$_DEVEL_EXISTS" == "true" ]; then
    git merge --no-ff -X theirs devel
  fi
  git tag -a -m "${COMMIT_MESSAGE_HEAD} ${FEATURE_VERSION}" v${FEATURE_VERSION}
  if [ "$_DEVEL_EXISTS" == "true" ]; then
    git checkout devel
    git merge --no-ff master
  fi
  if [ "${REMOTE_UPDATE}" == "true" ]; then
    git push origin master v${STABLE_VERSION} v${FEATURE_VERSION}
    if [ "$_DEVEL_EXISTS" == "true" ]; then
      git push origin devel
    fi
  fi
}

parse_opt "$@"
init
main
fini
exit 0
