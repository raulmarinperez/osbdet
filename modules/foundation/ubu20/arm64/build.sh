#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions

# debug
#   desc: Display a debug message if LOGLEVEL is DEBUG
#   params:
#     $1 - Debug message
#   return (status code/stdout):
debug() {
  if [[ "$LOGLEVEL" == "DEBUG" ]]; then
    echo $1
  fi
}

create_osbdetuser(){
  debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] Starting osbdet user creation" >> $OSBDET_LOGFILE
  if [ ! -d "/home/osbdet" ]
  then
    useradd -m -s /bin/bash osbdet
    echo osbdet:osbdet123$ | chpasswd 2> /dev/null
    debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet user created" >> $OSBDET_LOGFILE
  else
    debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet already existed and wasn't created" >> $OSBDET_LOGFILE
  fi
  debug "foundation.create_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet user creation process done" >> $OSBDET_LOGFILE
}
remove_osbdetuser(){
  debug "foundation.remove_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] Starting osbdet user deletion" >> $OSBDET_LOGFILE
  deluser --remove-home osbdet >> $OSBDET_LOGFILE
  debug "foundation.remove_osbdetuser DEBUG [`date +"%Y-%m-%d %T"`] osbdet user deletion done" >> $OSBDET_LOGFILE
}

miscinstall(){
  debug "foundation.miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous software installation" >> $OSBDET_LOGFILE
  apt update >> $OSBDET_LOGFILE 2>&1
  apt install -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common tmux python3-pip sudo git emacs >> $OSBDET_LOGFILE 2>&1
  debug "foundation.miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous software installation done" >> $OSBDET_LOGFILE
}
remove_miscinstall(){
  debug "foundation.remove_miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous software uninstallation" >> $OSBDET_LOGFILE
  apt remove -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common tmux python3-pip sudo git --purge >>$OSBDET_LOGFILE 2>&1
  apt autoremove -y >>$OSBDET_LOGFILE 2>&1
  debug "foundation.remove_miscinstall DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous software uninstallation done" >> $OSBDET_LOGFILE
}

miscsetup() {
  debug "foundation.miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous setup" >> $OSBDET_LOGFILE
  usermod -aG sudo osbdet
  #sed -i "s/^127.0.0.1\tlocalhost/127.0.0.1\tlocalhost\tosbdet/" /etc/hosts
  #sed -i "s/^127.0.1.1\tosbdet/#127.0.1.1\tosbdet/" /etc/hosts
  su osbdet -c "mkdir -p /home/osbdet/bin" >> $OSBDET_LOGFILE 2>&1
  cp $SCRIPT_PATH/../../osbdet-update.sh /home/osbdet/bin
  cp $SCRIPT_PATH/../../osbdet-recipes.sh /home/osbdet/bin
  cp $SCRIPT_PATH/../../osbdet-cook.sh /home/osbdet/bin
  chown -R osbdet:osbdet /home/osbdet/bin
  debug "foundation.miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous setup done" >> $OSBDET_LOGFILE
}
remove_miscsetup() {
  debug "foundation.remove_miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Starting miscellaneous setup removal" >> $OSBDET_LOGFILE
  deluser osbdet sudo >> $OSBDET_LOGFILE
  sed -i "s/^127.0.0.1\tlocalhost\tosbdet/127.0.0.1\tlocalhost/" /etc/hosts
  sed -i "s/^#127.0.1.1\tosbdet/127.0.1.1\tosbdet/" /etc/hosts
  debug "foundation.remove_miscsetup DEBUG [`date +"%Y-%m-%d %T"`] Miscellaneous setup removal done" >> $OSBDET_LOGFILE
}

install_jdk8_11(){
  debug "foundation.install_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] Removing AdoptOpenJDK repo" >> $OSBDET_LOGFILE
  apt install -y openjdk-11-jdk-headless openjdk-8-jdk-headless >> $OSBDET_LOGFILE 2>&1
  debug "foundation.install_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] AdoptOpenJDK repo removed" >> $OSBDET_LOGFILE
}
remove_jdk8_11(){
  debug "foundation.remove_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] Installing JDK 8 and 11" >> $OSBDET_LOGFILE
  apt remove -y openjdk-11-jdk-headless openjdk-8-jdk-headless --purge >> $OSBDET_LOGFILE 2>&1
  debug "foundation.remove_jdk8_11 DEBUG [`date +"%Y-%m-%d %T"`] JDK 8 and 11 installation done" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "foundation.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Creating the osbdet system user
  #   2. Installation miscellaneous software
  #   3. Miscellaneous setup
  #   4. Installing JDK 8 and 11
  printf "  Installing module 'foundation' ... "
  create_osbdetuser
  miscinstall
  miscsetup
  install_jdk8_11
  printf "[Done]\n"
  debug "foundation.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/home/osbdet" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "foundation.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Uninstalling JDK 8 and 11
  #   2. Miscellaneous setup
  #   3. Uninstallation miscellaneous software
  #   4. Removing the osbdet system user
  #   
  printf "  Uninstalling module 'foundation' ... "
  remove_jdk8_11
  remove_miscsetup
  remove_miscinstall
  remove_osbdetuser
  printf "[Done]\n"
  debug "foundation.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'foundation\' module
  echo Usage: script.sh [OPTION]
  echo 
  echo Available options for this module:
  echo "  install             module installation"
  echo "  status              module installation status check"
  echo "  uninstall           module uninstallation"
}

main(){
  # 1. Set logfile to /dev/null if it doesn't exist
  if [ -z "$OSBDET_LOGFILE" ] ; then
    export OSBDET_LOGFILE=/dev/null
  fi
  # 2. Main function
  debug "foundation DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the foundation module" >> $OSBDET_LOGFILE
  if [ $# -eq 1 ]
  then
    if [ "$1" == "install" ]
    then
      module_install
    elif [ "$1" == "status" ]
    then
      module_status
    elif [ "$1" == "uninstall" ]
    then
      module_uninstall
    else
      usage
      exit -1
    fi
  else
    usage
    exit -1
  fi
  debug "foundation DEBUG [`date +"%Y-%m-%d %T"`] Activity with the foundation module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
