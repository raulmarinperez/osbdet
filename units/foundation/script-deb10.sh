#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions

_foundation_osbdetuser(){
  if [ ! -d "/home/osbdet" ]
  then
    useradd -m -s /bin/bash osbdet
    echo osbdet:osbdet123$ | chpasswd 2> /dev/null
  else
    echo "    osbdet user already exists"
  fi
}
_foundation_remove_osbdetuser(){
  deluser --remove-home osbdet
}

_foundation_miscinstall(){
  apt update
  apt install -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common tmux python3-pip sudo git
}
_foundation_remove_miscinstall(){
  apt remove -y apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common tmux python3-pip sudo git --purge
  apt autoremove -y
}

_foundation_miscsetup() {
  usermod -aG sudo osbdet
  sed -i "s/^127.0.0.1\tlocalhost/127.0.0.1\tlocalhost\tosbdet/" /etc/hosts
  sed -i "s/^127.0.1.1\tosbdet/#127.0.1.1\tosbdet/" /etc/hosts
}
_foundation_remove_miscsetup() {
  deluser osbdet sudo
  sed -i "s/^127.0.0.1\tlocalhost\tosbdet/127.0.0.1\tlocalhost/" /etc/hosts
  sed -i "s/^#127.0.1.1\tosbdet/127.0.1.1\tosbdet/" /etc/hosts
}

_foundation_adoptopenjdkrepo(){
  wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
  add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
  apt update
}
_foundation_remove_adoptopenjdkrepo(){
  apt-key del `apt-key list | $SCRIPT_PATH/../../shared/givemekey.awk -v pattern=AdoptOpenJDK`
  add-apt-repository --yes -r https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
  apt update
}

_foundation_jdk8_11(){
  apt install -y adoptopenjdk-8-hotspot adoptopenjdk-11-hotspot
}
_foundation_remove_jdk8_11(){
  apt remove -y adoptopenjdk-8-hotspot adoptopenjdk-11-hotspot
}

# Primary functions
#
unit_install(){
  echo Starting foundation_install...

  _foundation_osbdetuser
  echo "    osbdet user creation [Done]"
  _foundation_miscinstall
  echo "    Misc installation [Done]"
  _foundation_miscsetup
  echo "    Misc setup [Done]"
  _foundation_adoptopenjdkrepo
  echo "    Adding Adopt OpenJDK repo [Done]"
  _foundation_jdk8_11
  echo "    Adopt OpenJDK 8 and 11 installation [Done]"
}

unit_status() {
  echo Checking foundation unit installation status...
  if [ -d "/home/osbdet" ]
  then
    echo "    Foundation unit is installed [OK]"
    exit 0
  else
    echo "    Foundation unit is not installed [KO]"
    exit -1
  fi
}

unit_uninstall(){
  echo Starting foundation_uninstall...

  _foundation_remove_jdk8_11
  echo "    Adopt OpenJDK 8 and 11 uninstallation [Done]"
  _foundation_remove_adoptopenjdkrepo
  echo "    Removing Adopt OpenJDK repo [Done]"
  _foundation_remove_miscsetup
  echo "    Misc setup removal [Done]"
  _foundation_remove_miscinstall
  echo "    Misc uninstallation [Done]"
  _foundation_remove_osbdetuser
  echo "    osbdet user removal [Done]"
}

usage() {
  echo Starting \'foundation\' unit
  echo Usage: script.sh [OPTION]
  echo 
  echo Available options for this unit:
  echo "  install             unit installation"
  echo "  status              unit installation status check"
  echo "  uninstall           unit uninstallation"
}

main(){
  if [ $# -eq 1 ]
  then
    if [ "$1" == "install" ]
    then
      unit_install
    elif [ "$1" == "status" ]
    then
      unit_status
    elif [ "$1" == "uninstall" ]
    then
      unit_uninstall
    else
      usage
      exit -1
    fi
  else
    usage
    exit -1
  fi
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
