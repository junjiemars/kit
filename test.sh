#!/bin/sh

_ROOT_DIR_="`cd -- $(dirname -- $0) && pwd`"
_TEST_="${_TEST_:-basic}"


# switch to ROOT
cd "${_ROOT_DIR_}"

test_do() {
  echo "test $@ ..."
  $@
}

test_after() {
  local rc="${HOME}/.$(basename $SHELL)rc"
  if [ -f "$rc" -a -n "$GITHUB_ACTIONS" ]; then
    sed -i.b0 's/^# o_export_path_env=no/o_export_path_env=yes/' "$rc"
  fi
}

# echo env before Nore
echo "------------"
env
echo "------------"

# basic test
if [ "basic" = "$_TEST_" ]; then
  test_do $SHELL $DEBUG ul/sh.sh
fi

# echo env after Nore

echo "++++++++++++"
test_after
$SHELL -l -c 'env'
echo "++++++++++++"

echo "!completed"

# eof
