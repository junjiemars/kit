#!/bin/bash
# usage: curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/setup-emacs-desktop.sh|sudo bash

[ 0 -ne `type -p emacs >/dev/null;echo $?` ] && exit 1

EMACS_VS=${EMACS_VS:-`emacs -nw --version|head -n1`}
if [ -z "${EMACS_VS}" ]; then
  exit 1
fi 

EMACS_VN="`echo ${EMACS_VS}|cut -d' ' -f3`"
if [ -z "${EMACS_VN}" ]; then
  exit 1
fi

IFS='.' read -ra EMACS_VA <<< "${EMACS_VN}"
[ 1 -gt ${#EMACS_VA[@]} ] && exit 1

EMACS_DESKTOP=${EMACS_DESKTOP:-"/usr/share/applications/emacs${EMACS_VA[0]}.desktop"}
cat <<END >${EMACS_DESKTOP}
[Desktop Entry]
Version=1.0
Name=GNU Emacs ${EMACS_VA[0]}
GenericName=Text Editor
Comment=View and edit files
MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
Exec=/usr/bin/emacs24 %F
TryExec=emacs24
Icon=/usr/share/icons/hicolor/scalable/apps/emacs${EMACS_VA[0]}.svg
Type=Application
Terminal=false
Categories=Utility;Development;TextEditor;
StartupWMClass=Emacs${EMACS_VA[0]}
END
chmod u+x ${EMACS_DESKTOP}
