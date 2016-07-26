#!/bin/bash

SQLD_HOME=${SQLD_HOME:-"/opt/open/sqldeveloper"}
SQLD_DESKTOP='/usr/share/applications/sqldeveloper.desktop'

if [ 0 -eq `type -p java &>/dev/null; echo $?` ]; then

cat <<END >${SQLD_DESKTOP}
[Desktop Entry]
Name=SQL Developer
Exec=${SQLD_HOME}/sqldeveloper.sh
Type=Application
StartupNotify=true
Categories=Development;
Comment=SQL Developer
Path=/tmp
Icon=${SQLD_HOME}/icon.png
Name[en_US]=SQL Developer
END
  chmod 644 ${SQLD_DESKTOP}

fi
