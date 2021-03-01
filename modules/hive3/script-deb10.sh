#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions
_hive3_getandextract() {
  wget http://apache.uvigo.es/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz \
       -O /opt/apache-hive-3.1.2-bin.tar.gz
  echo "    Hive 3.1.2 download [Done]"

  tar zxf /opt/apache-hive-3.1.2-bin.tar.gz -C /opt
  rm /opt/apache-hive-3.1.2-bin.tar.gz
  ln -s /opt/apache-hive-3.1.2-bin /opt/hive
  chown -R osbdet:osbdet /opt/hive* /opt/apache-hive*
}
_hive3_removal() {
  rm -rf /opt/*hive*
}

_hive3_setenvvars() {
  export HIVE_HOME=/opt/hive
  export HADOOP_HOME=/opt/hadoop
  export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64
  export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH
}

_hadoop3_setenvvars() {
  export HADOOP_HOME=/opt/hadoop
  export HADOOP_COMMON_HOME=/opt/hadoop
  export HADOOP_HDFS_HOME=/opt/hadoop
  export HADOOP_MAPRED_HOME=/opt/hadoop
  export HADOOP_YARN_HOME=/opt/hadoop
  export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
  export HDFS_DATANODE_USER=osbdet
  export HDFS_NAMENODE_USER=osbdet
  export HDFS_SECONDARYNAMENODE_USER=osbdet
  export YARN_RESOURCEMANAGER_USER=osbdet
  export YARN_NODEMANAGER_USER=osbdet
  export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
  export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64
  export PATH=$PATH:$JAVA_HOME/bin
}

_hive3_metastoreinit() {
  # Guava libraries replacement due to a bug:
  #   - https://issues.apache.org/jira/browse/HIVE-22915
  #   - https://issues.apache.org/jira/browse/HIVE-22718
  rm $HIVE_HOME/lib/guava-19.0.jar
  cp $HADOOP_HOME/share/hadoop/hdfs/lib/guava-27.0-jre.jar $HIVE_HOME/lib/

  cd $HIVE_HOME
  $HIVE_HOME/bin/schematool -dbType derby -initSchema
  chown -R osbdet:osbdet $HIVE_HOME/metastore_db
  chown osbdet:osbdet $HIVE_HOME/derby.log
  cd $OLDPWD
}

_hive3_hadoopsetup() {
  cp $HADOOP_HOME/etc/hadoop/core-site.xml $SCRIPT_PATH/core-site.xml.orig 
  cp $SCRIPT_PATH/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
  chown osbdet:osbdet $HADOOP_HOME/etc/hadoop/core-site.xml
}
_hive3_remove_hadoopsetup() {
  cp $SCRIPT_PATH/core-site.xml.orig $HADOOP_HOME/etc/hadoop/core-site.xml
  chown osbdet:osbdet $HADOOP_HOME/etc/hadoop/core-site.xml
}

_hive3_tezinstall() {
  mkdir -p /opt/tez-0.9.2/conf
  ln -s /opt/tez-0.9.2 /opt/tez

  tar zxf $SCRIPT_PATH/tez-0.9.2-minimal.tar.gz -C /opt/tez
  cp $SCRIPT_PATH/tez-site.xml /opt/tez/conf

  chown -R osbdet:osbdet /opt/tez*
}
_hive3_remove_tezinstall() {
  rm -rf /opt/tez*
}

_hive3_tezhdfssetup() {
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/start-dfs.sh'
  export HADOOP_USER_NAME=osbdet
  $HADOOP_HOME/bin/hdfs dfsadmin -safemode leave
  $HADOOP_HOME/bin/hdfs dfs -mkdir -p /apps/tez-0.9.2
  $HADOOP_HOME/bin/hdfs dfs -put $SCRIPT_PATH/tez-0.9.2.tar.gz /apps/tez-0.9.2
  $HADOOP_HOME/bin/hdfs dfs -chown -R osbdet:hadoop /apps
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/stop-dfs.sh'
}
_hive3_remove_tezhdfssetup() {
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/start-dfs.sh'
  export HADOOP_USER_NAME=osbdet
  $HADOOP_HOME/bin/hdfs dfsadmin -safemode leave
  $HADOOP_HOME/bin/hdfs dfs -rm -r /apps/tez-0.9.2
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/stop-dfs.sh'
}

_hive3_initscript() {
  cp $SCRIPT_PATH/hiveserver.service /lib/systemd/system/hiveserver.service
  cp $SCRIPT_PATH/hiveserver2-start.sh $HIVE_HOME/bin
  chmod 644 /lib/systemd/system/hiveserver.service
  chown osbdet:osbdet $HIVE_HOME/bin/hiveserver2-start.sh
  systemctl daemon-reload
}
_hive3_remove_initscript() {
  rm /lib/systemd/system/hiveserver.service
  systemctl daemon-reload
}

_hive3_userprofile() {
  echo >> /home/osbdet/.profile
  echo '# set HIVE_HOME and add its bin folder to the PATH' >> /home/osbdet/.profile
  echo 'export HIVE_HOME=/opt/hive' >> /home/osbdet/.profile
  echo 'PATH="$PATH:$HIVE_HOME/bin"' >> /home/osbdet/.profile
}
_hive3_remove_userprofile() {
  # remove the break line before the user profile setup for Hive
  #   - https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern
  #   - https://unix.stackexchange.com/questions/29906/delete-range-of-lines-above-pattern-with-sed-or-awk
  tac /home/osbdet/.profile > /home/osbdet/.eliforp
  sed -i '/^# set HIVE.*/{n;d}' /home/osbdet/.eliforp

  rm /home/osbdet/.profile
  tac /home/osbdet/.eliforp > /home/osbdet/.profile
  chown osbdet:osbdet /home/osbdet/.profile

  # remove user profile setup for Hive
  sed -i '/^# set HIVE.*/,+3d' /home/osbdet/.profile
  rm -f /home/osbdet/.eliforp

}

# Primary functions
#
unit_install(){
  echo Starting Hive 3 deployment...

  #_hive3_getandextract
  #echo "    Hive 3.1.2 extraction and initial setup [Done]"
  #_hive3_setenvvars
  #_hive3_metastoreinit
  #echo "    Hive metastore setup [Done]"
  #_hive3_hadoopsetup
  #echo "    Update Hadoop files for impersonation [Done]"
  #_hive3_tezinstall
  #echo "    Extracting Tez 0.9.2 (custom build) [Done]"
  #_hadoop3_setenvvars
  #_hive3_tezhdfssetup
  #echo "    Adding Tez 0.9.2 jar file into HDFS [Done]"

  #_hive3_initscript
  #echo "    Init script creation and automatic start after booting [Done]"
  #_hive3_userprofile
  #echo "    User's environment variables setup [Done]"
}

unit_status() {
  if [ -L "/opt/hive" ]
  then
    echo "Unit is installed [OK]"
    exit 0
  else
    echo "Unit is not installed [KO]"
    exit 1
  fi
}

unit_uninstall(){
  echo Starting hive3_uninstall...

  _hive3_remove_userprofile
  echo "    User's environment variables removal [Done]"
  _hive3_remove_initscript
  echo "    Init script and automatic start after booting removal [Done]"
  _hadoop3_setenvvars
  _hive3_remove_tezhdfssetup
  echo "    Tez 0.9.2 jar file removal from HDFS [Done]"
  _hive3_remove_tezinstall
  echo "    Tez 0.9.2 (custom build) removal [Done]"
  _hive3_remove_hadoopsetup
  echo "    Hadoop files for impersonation removal [Done]"
  _hive3_removal
  echo "    Hive 3.1.2 removal [Done]"
}

usage() {
  echo Starting \'hive3\' unit
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
  export SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
