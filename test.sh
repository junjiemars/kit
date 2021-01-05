#!/bin/sh

_ROOT_DIR_="`cd -- $(dirname -- $0) && pwd`"
_TEST_="${_TEST_:-basic}"
_OS_NAME_="`uname -s 2>/dev/null`"

case "$_OS_NAME_" in
  MSYS_NT-*|MINGW??_NT-*) _OS_NAME_="WinNT" ;;
esac

# switch to ROOT
cd "${_ROOT_DIR_}"

test_do() {
  echo "test $@ ..."
  $@
}

# echo env
echo "------------"
env
echo "------------"

# basic test
if [ "basic" = "$_TEST_" ]; then
  test_do ul/sh.sh       || exit 1
fi

# eof
