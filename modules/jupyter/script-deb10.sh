#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions

_jupyter_install(){
  pip3 install jupyter numpy mcpi 
}
_jupyter_remove(){
  pip3 uninstall -y jupyter numpy mcpi
}

_jupyter_initialsetup(){
  su osbdet -c "mkdir /home/osbdet/notebooks"
  su osbdet -c "jupyter notebook --generate-config"
  sed -i "s/^#c\.NotebookApp\.ip = 'localhost'/c\.NotebookApp\.ip = '\*'/" /home/osbdet/.jupyter/jupyter_notebook_config.py
  sed -i "s/^#c\.NotebookApp\.password = ''/c\.NotebookApp\.password = 'sha1:51a108786a75:0798779c484abd8a6218db7d4e9d3370ffbcd9c8'/"\
         /home/osbdet/.jupyter/jupyter_notebook_config.py
  sed -i "s/^#c\.NotebookApp\.notebook\_dir = ''/c\.NotebookApp\.notebook\_dir = '\/home\/osbdet\/notebooks'/"\
         /home/osbdet/.jupyter/jupyter_notebook_config.py
}
_jupyter_remove_initialsetup(){
  rm -rf /home/osbdet/.jupyter /home/osbdet/notebooks
}

_jupyter_serviceinstall(){
  cp $SCRIPT_PATH/jupyter.service /lib/systemd/system/jupyter.service
  chmod 644 /lib/systemd/system/jupyter.service
  systemctl daemon-reload
  systemctl enable jupyter.service
}
_jupyter_remove_serviceinstall(){
  service jupyter stop
  systemctl disable jupyter.service
  rm /lib/systemd/system/jupyter.service 
  systemctl daemon-reload
}

# Primary functions
#
unit_install(){
  echo Starting jupyter_install...

  #_jupyter_install
  #echo "    Jupyter and additional packages installed [Done]"
  #_jupyter_initialsetup
  #echo "    Folder for notebooks creation and initial setup [Done]"
  #_jupyter_serviceinstall
  #echo "    Init script creation and automatic start after booting [Done]"
}

unit_status() {
  if [ -d "/home/osbdet/.jupyter" ]
  then
    echo "Unit is installed [OK]"
    exit 0
  else
    echo "Unit is not installed [KO]"
    exit 1
  fi
}

unit_uninstall(){
  echo Starting jupyter_uninstall...

  _jupyter_remove_serviceinstall
  echo "    Init script removal [Done]"
  _jupyter_remove_initialsetup
  echo "    Folder for notebooks creation and initial setup [Done]"
  _jupyter_remove
  echo "    Jupyter and additional packages installed [Done]"
}

usage() {
  echo Starting \'jupyter\' unit
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
