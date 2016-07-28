#!/bin/bash

PREFIX=${PREFIX:-'/opt/run/bin'}
OPEN_DIR=${OPEN_DIR:-'/opt/open'}
KITS=(
      'install_ant'
      #'install_maven'
      #'install_boot'
      #'install_gradle'
      #'install_groovy'
      #'install_scala'
)


install_ant() {
  ANT_HOME="${OPEN_DIR}/ant"
  ANT_URL=${ANT_URL:-'https://github.com/apache/ant.git'}

  cd "${OPEN_DIR}"
  [ -f "${ANT_HOME}/bootstrap.sh" ] || git clone --depth 1 ${ANT_URL} 
  cd "${ANT_HOME}" && bash ./bootstrap.sh && \
  echo -e "PATH=$PATH:$ANT_HOME" >> $HOME/.bash_paths
}

install_boot() {
  BOOT_URL=${BOOT_URL:-'https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh '}

  cd "${PREFIX}" && \
  curl -fsSLo boot ${BOOT_URL} && chmod 755 boot
}

for i in "${KITS[@]}"; do
  echo -e "call ${i} ..." && ${i} && echo -e "\n${i} installed."
done
