#!/bin/bash
# sudo bash <(curl https://raw.githubusercontent.com/junjiemars/kit/ubuntu/setup-idea-desktop.sh)

IDEA_HOME=${IDEA_HOME:-"/opt/open/idea/idea-IC-163.7743.44"}

if [ -d "$IDEA_HOME" ]; then
  echo "$IDEA_HOME no found, panic!"
fi

# make idea run from terminal
IDEA_TTY='/usr/local/bin/idea'
cat <<END >${IDEA_TTY}
#!/bin/bash
${IDEA_HOME}/bin/idea.sh \$@ 2>&1 1>/tmp/idea.log
END
chmod u+x ${IDEA_TTY}

# make idea run from desktop
IDEA_DESKTOP='/usr/share/applications/idea.desktop'
cat <<END >${IDEA_DESKTOP}
[Desktop Entry]
Name=IntelliJ IDEA `date +%G`
Exec=${IDEA_HOME}/bin/idea.sh
Type=Application
StartupNotify=true
Categories=Development;
Comment=IntelliJ IDEA
Path=/tmp
Icon=${IDEA_HOME}/bin/idea.png
Name[en_US]=IntelliJ IDEA `date +%G`
END
chmod 644 ${IDEA_DESKTOP}
