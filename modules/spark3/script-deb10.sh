#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions

_spark3_getandextract(){
  wget http://apache.uvigo.es/spark/spark-3.0.0/spark-3.0.0-bin-hadoop3.2.tgz \
       -O /opt/spark-3.0.0-bin-hadoop3.2.tgz
  echo "    Spark 3 (Hadoop 3.2) downloaded [Done]"

  tar zxf /opt/spark-3.0.0-bin-hadoop3.2.tgz -C /opt
  rm /opt/spark-3.0.0-bin-hadoop3.2.tgz
  chown -R osbdet:osbdet /opt/spark-3.0.0-bin-hadoop3.2
  pip3 install findspark
}
_spark3_removal(){
  rm -rf /opt/spark-3.0.0-bin-hadoop3.2
  pip3 uninstall -y findspark
}

_spark3_jupyterspark(){
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop
     cp $SCRIPT_PATH/jupyter.service /lib/systemd/system/jupyter.service
     chmod 644 /lib/systemd/system/jupyter.service
     rm -f /etc/systemd/system/jupyter.service
     ln -s /lib/systemd/system/jupyter.service /etc/systemd/system/jupyter.service
     systemctl daemon-reload
     systemctl enable jupyter.service
     service jupyter start
     echo "    Jupyter init script update [Done]"
  else
     echo "    Jupyter init script skipped, not found [Done]"
  fi
}
_spark3_remove_jupyterspark(){
  if [ -f "/lib/systemd/system/jupyter.service" ]
  then
     service jupyter stop
     cp $SCRIPT_PATH/jupyter_nospark3.service /lib/systemd/system/jupyter.service
     chmod 644 /lib/systemd/system/jupyter.service
     rm -f /etc/systemd/system/jupyter.service
     ln -s /lib/systemd/system/jupyter.service /etc/systemd/system/jupyter.service
     systemctl daemon-reload
     systemctl enable jupyter.service
     service jupyter start
     echo "    Jupyter init script update [Done]"
  else
     echo "    Jupyter init script skipped, not found [Done]"
  fi
}

_spark3_userprofile(){
  echo '# set SPARK_HOME and its bin folder to the PATH' >> /home/osbdet/.profile                                                   
  echo 'SPARK_HOME=/opt/spark-3.0.0-bin-hadoop3.2/' >> /home/osbdet/.profile                                                 
  echo 'HADOOP_HOME=/opt/spark-3.0.0-bin-hadoop3.2/' >> /home/osbdet/.profile                                                
  echo 'PATH="$PATH:$SPARK_HOME/bin"' >> /home/osbdet/.profile
}
_spark3_remove_userprofile(){
  sed -i '/^# set SPARK.*/,+3d' ~osbdet/.profile
}

# Primary functions
#
unit_install(){
  echo Starting spark3_install...

  _spark3_getandextract
  echo "    Spark 3 extraction and findspark installation  [Done]"
  _spark3_jupyterspark
  echo "    Spark support for Jupyter service setup [Done]"
  _spark3_userprofile
  echo "    User's environment variables setup [Done]"
}

unit_status() {
  if [ -d "/opt/spark-3.0.0-bin-hadoop3.2" ]
  then
    echo "Unit is installed [OK]"
    exit 0
  else
    echo "Unit is not installed [KO]"
    exit -1
  fi
}

unit_uninstall(){
  echo Starting spark3_uninstall...

  _spark3_remove_userprofile
  echo "    User's environment variables removal [Done]"
  _spark3_remove_jupyterspark
  echo "    Spark support for Jupyter service removal [Done]"
  _spark3_removal
  echo "    Spark 3 extraction and findspark deletion  [Done]"
}

usage() {
  echo Starting \'spark3\' unit
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
