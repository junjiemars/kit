#!/bin/bash
# usage: 
# --------------------
# ```sh
# curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/setup-emacs-desktop.sh|sudo bash
# ```
# -------------------- 


E_BIN_PATH="${E_BIN_PATH:-`type -p emacs 2>/dev/null`}"
E_TERMINAL=( "no" "yes" )
E_VERSION=
E_VERSIONS=()
E_PREFIX=
E_NAME=
E_DESKTOP_NAME=
E_EXEC=


check_version() {
	local b="$1"
	
	if [ ! -x "$b" ]; then
		echo "!invalid emacs bin path: $b"
		return 1
	fi

	local v="`$b -nw --version | head -n1 | cut -d' ' -f3`"
	if [ -z "$v" ]; then
		echo "!get version info from: $b failed"
		return 1
	fi 

	echo "$v"
	return 0
}


get_ver_numbers() {
	local s="$1"
	local v=()

	IFS='.' read -ra v <<< "$s"
	if [ 1 -gt ${#v[@]} ]; then
		echo "!extract version numbers from: $s failed"
		return 1
	fi
	echo "${v[@]}"
	return 0
}


get_prefix() {
	local b="$1"
	local p="$(dirname `dirname $b`)"
	if [ 0 -ne $? ]; then
		echo "!get emacs' prefix from: $b failed"
		return 1
	fi
	echo "$p"
	return 0
}


for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --emacs-bin-path=*)      e_bin_path="$value" 		    ;;
    --terminal)              E_TERMINAL="yes"  		      ;;

    *)
			echo "$0: error: invalid option \"$option\""
			exit 1
    ;;
  esac
done

retval=1

if [ -n "$e_bin_path" ]; then
	E_VERSION="`check_version $e_bin_path`"
	retval=$?
	if [ 0 -ne $retval ]; then
		echo "!valid emacs no found at: $e_bin_path"
	else
		E_BIN_PATH=$e_bin_path
	fi
fi

if [ 0 -ne $retval ]; then
	E_VERSION="`check_version $E_BIN_PATH`"
	retval=$?
	if [ 0 -ne $retval ]; then
		echo "!valid emacs no found at: $E_BIN_PATH"
		exit 1
	fi
fi

E_PREFIX="`get_prefix $E_BIN_PATH`"
retval=$?
if [ 0 -ne $retval ]; then
	exit 1
fi

E_VERSIONS=( `get_ver_numbers $E_VERSION` )

if [ "yes" = "$E_TERMINAL" ]; then
	E_NAME="Emacs ${E_VERSIONS[0]} (Terminal)"
	E_DESKTOP_NAME="emacs${E_VERSIONS[0]}-term.desktop"
	E_EXEC="$E_BIN_PATH -nw %F"
else
	E_NAME="Emacs ${E_VERSIONS[0]} (GUI)"
	E_DESKTOP_NAME="emacs${E_VERSIONS[0]}.desktop"
	E_EXEC="$E_BIN_PATH %F"
fi

cat << END >${E_DESKTOP_NAME}
[Desktop Entry]
Version=1.1
Name=$E_NAME
GenericName=Text Editor
Comment=View and edit files
MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
Exec=${E_EXEC}
TryExec=emacs$(( ${E_VERSIONS[0]}-1 ))
Icon=${E_PREFIX%/}/share/icons/hicolor/scalable/apps/emacs.svg
Type=Application
Terminal=$E_TERMINAL
Categories=Utility;Development;TextEditor;
StartupWMClass=Emacs
END

chmod 644 ${E_DESKTOP_NAME}
