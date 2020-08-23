#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions
_nifi_getandextract(){
  wget http://apache.uvigo.es/nifi/1.12.0/nifi-1.12.0-bin.tar.gz \
       -O /opt/nifi-1.12.0-bin.tar.gz
  tar zxf /opt/nifi-1.12.0-bin.tar.gz -C /opt
  rm /opt/nifi-1.12.0-bin.tar.gz
  ln -s /opt/nifi-1.12.0 /opt/nifi
  chown -R osbdet:osbdet /opt/nifi*
}
_nifi_remove(){
  rm -rf /opt/nifi*
}

_nifi_setjavahome(){
  # From https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/
  sed -i 's+^#export JAVA_HOME.*+export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-11-hotspot-amd64+' \
         /opt/nifi/bin/nifi-env.sh
}

_nifi_userprofile(){
  echo >> /home/osbdet/.profile
  echo '# Add NiFi''s bin folder to the PATH' >> /home/osbdet/.profile
  echo 'PATH="$PATH:/opt/nifi/bin"' >> /home/osbdet/.profile
}
_nifi_remove_userprofile(){
  # remove the break line before the user profile setup for NiFi
  #   - https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern                                     
  #   - https://unix.stackexchange.com/questions/29906/delete-range-of-lines-above-pattern-with-sed-or-awk                            
  tac /home/osbdet/.profile > /home/osbdet/.eliforp
  sed -i '/^# Add NiFi.*/{n;d}' /home/osbdet/.eliforp

  rm /home/osbdet/.profile
  tac /home/osbdet/.eliforp > /home/osbdet/.profile
  chown osbdet:osbdet /home/osbdet/.profile

  # remove user profile setup for NiFi
  sed -i '/^# Add NiFi.*/,+2d' /home/osbdet/.profile
  rm -f /home/osbdet/.eliforp
}

# Primary functions
#
unit_install(){
  echo Starting nifi_install...

  _nifi_getandextract
  echo "    NiFi downloading and extraction [Done]"
  _nifi_setjavahome
  echo "    Setting up JAVA_HOME for NiFi [Done]"
  _nifi_userprofile
  echo "    Adding NiFi's bin folder to user's PATH [Done]"
}

unit_status() {
  echo Checking nifi unit installation status...
  if [ -L "/opt/nifi" ]
  then
    echo "    NiFi unit is installed [OK]"
    exit 0
  else
    echo "    NiFi unit is not installed [KO]"
    exit -1
  fi
}

unit_uninstall(){
  echo Starting nifi_uninstall...

  _nifi_remove_userprofile
  echo "    NiFi's bin folder to user's PATH removal [Done]"
  _nifi_remove
  echo "    NiFi removal [Done]"
}

usage() {
  echo Starting \'nifi\' unit
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
