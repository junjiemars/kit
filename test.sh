#!/bin/sh

_ROOT_DIR_="`cd -- $(dirname -- $0) && pwd`"
_TEST_="${_TEST_:-basic}"


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
  test_do $SHELL ul/sh.sh       || exit 1
fi

# eof
