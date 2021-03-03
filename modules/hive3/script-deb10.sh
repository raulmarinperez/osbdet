#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""
HIVE_BINARY_URL=http://apache.uvigo.es/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz
HIVE_TGZ_FILE=apache-hive-3.1.2-bin.tar.gz
HIVE_DEFAULT_DIR=apache-hive-3.1.2-bin

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

getandextract() {
  debug "hive3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Downloading and extracting Hive 3" >> $OSBDET_LOGFILE
  wget $HIVE_BINARY_URL -O /opt/$HIVE_TGZ_FILE >> $OSBDET_LOGFILE 2>&1
  tar zxf /opt/$HIVE_TGZ_FILE -C /opt >> $OSBDET_LOGFILE 2>&1
  rm /opt/$HIVE_TGZ_FILE
  mv /opt/$HIVE_DEFAULT_DIR /opt/hive3
  chown -R osbdet:osbdet /opt/hive3
  debug "hive3.getandextract DEBUG [`date +"%Y-%m-%d %T"`] Hive 3 downloading and extracting process done" >> $OSBDET_LOGFILE
}
removal() {
  debug "hive3.removal DEBUG [`date +"%Y-%m-%d %T"`] Removing Hive 3" >> $OSBDET_LOGFILE
  rm -rf /opt/hive3
  debug "hive3.removal DEBUG [`date +"%Y-%m-%d %T"`] Hive 3 removed" >> $OSBDET_LOGFILE
}

setenvvars() {
  debug "hive3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Setting the environment variables for the installation process" >> $OSBDET_LOGFILE
  export HIVE_HOME=/opt/hive3
  export HADOOP_HOME=/opt/hadoop3
  export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64
  export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH
  debug "hive3.setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Environment variables already defined" >> $OSBDET_LOGFILE
}

hadoop3_setenvvars() {
  debug "hive3.hadoop3_setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Setting the environment variables for the installation process" >> $OSBDET_LOGFILE
  export HADOOP_HOME=/opt/hadoop3
  export HADOOP_COMMON_HOME=/opt/hadoop3
  export HADOOP_HDFS_HOME=/opt/hadoop3
  export HADOOP_MAPRED_HOME=/opt/hadoop3
  export HADOOP_YARN_HOME=/opt/hadoop3
  export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
  export HDFS_DATANODE_USER=osbdet
  export HDFS_NAMENODE_USER=osbdet
  export HDFS_SECONDARYNAMENODE_USER=osbdet
  export YARN_RESOURCEMANAGER_USER=osbdet
  export YARN_NODEMANAGER_USER=osbdet
  export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
  export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64
  export PATH=$PATH:$JAVA_HOME/bin
  debug "hive3.hadoop3_setenvvars DEBUG [`date +"%Y-%m-%d %T"`] Environment variables already defined" >> $OSBDET_LOGFILE
}

metastoreinit() {
  debug "hive3.metastoreinit DEBUG [`date +"%Y-%m-%d %T"`] Hive Metastore initialization" >> $OSBDET_LOGFILE
  # Guava libraries replacement due to a bug:
  #   - https://issues.apache.org/jira/browse/HIVE-22915
  #   - https://issues.apache.org/jira/browse/HIVE-22718
  rm $HIVE_HOME/lib/guava-19.0.jar
  cp $HADOOP_HOME/share/hadoop/hdfs/lib/guava-27.0-jre.jar $HIVE_HOME/lib/

  cd $HIVE_HOME
  $HIVE_HOME/bin/schematool -dbType derby -initSchema >> $OSBDET_LOGFILE 2>&1
  chown -R osbdet:osbdet $HIVE_HOME/metastore_db
  chown osbdet:osbdet $HIVE_HOME/derby.log
  cd $OLDPWD
  debug "hive3.metastoreinit DEBUG [`date +"%Y-%m-%d %T"`] Hive Metastore initialization done" >> $OSBDET_LOGFILE
}

hadoopsetup() {
  debug "hive3.hadoopsetup DEBUG [`date +"%Y-%m-%d %T"`] Updating Hadoop 3 configuration files to support Hive 3" >> $OSBDET_LOGFILE
  cp $HADOOP_HOME/etc/hadoop/core-site.xml $SCRIPT_PATH/core-site.xml.orig 
  cp $SCRIPT_PATH/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
  chown osbdet:osbdet $HADOOP_HOME/etc/hadoop/core-site.xml
  debug "hive3.hadoopsetup DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 configuration files to support Hive 3 updated" >> $OSBDET_LOGFILE
}
remove_hadoopsetup() {
  debug "hive3.remove_hadoopsetup DEBUG [`date +"%Y-%m-%d %T"`] Removing Hadoop 3 configuration files to support Hive 3" >> $OSBDET_LOGFILE
  cp $SCRIPT_PATH/core-site.xml.orig $HADOOP_HOME/etc/hadoop/core-site.xml
  chown osbdet:osbdet $HADOOP_HOME/etc/hadoop/core-site.xml
  debug "hive3.remove_hadoopsetup DEBUG [`date +"%Y-%m-%d %T"`] Hadoop 3 configuration files to support Hive 3 removed" >> $OSBDET_LOGFILE
}

tezinstall() {
  debug "hive3.tezinstall DEBUG [`date +"%Y-%m-%d %T"`] Deploying TEZ inside HIVE_HOME" >> $OSBDET_LOGFILE
  mkdir -p /opt/hive3/tez/conf

  tar zxf $SCRIPT_PATH/tez-0.9.2-minimal.tar.gz -C /opt/hive3/tez
  cp $SCRIPT_PATH/tez-site.xml /opt/hive3/tez/conf

  chown -R osbdet:osbdet /opt/hive3/tez
  debug "hive3.tezinstall DEBUG [`date +"%Y-%m-%d %T"`] TEZ was deployed inside HIVE_HOME" >> $OSBDET_LOGFILE
}
remove_tezinstall() {
  debug "hive3.remove_tezinstall DEBUG [`date +"%Y-%m-%d %T"`] Removing TEZ from HIVE_HOME" >> $OSBDET_LOGFILE
  rm -rf /opt/hive3/tez
  debug "hive3.remove_tezinstall DEBUG [`date +"%Y-%m-%d %T"`] TEZ removed from HIVE_HOME" >> $OSBDET_LOGFILE
}

tezhdfssetup() {
  debug "hive3.tezhdfssetup DEBUG [`date +"%Y-%m-%d %T"`] Adding TEZ into HDFS" >> $OSBDET_LOGFILE
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/start-dfs.sh" >> $OSBDET_LOGFILE 2>&1
  export HADOOP_USER_NAME=osbdet
  $HADOOP_HOME/bin/hdfs dfsadmin -safemode leave >> $OSBDET_LOGFILE 2>&1
  $HADOOP_HOME/bin/hdfs dfs -mkdir -p /apps/tez-0.9.2 >> $OSBDET_LOGFILE 2>&1
  $HADOOP_HOME/bin/hdfs dfs -put $SCRIPT_PATH/tez-0.9.2.tar.gz /apps/tez-0.9.2 >> $OSBDET_LOGFILE 2>&1
  $HADOOP_HOME/bin/hdfs dfs -chown -R osbdet:hadoop /apps >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". $HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/stop-dfs.sh" >> $OSBDET_LOGFILE 2>&1
  debug "hive3.tezhdfssetup DEBUG [`date +"%Y-%m-%d %T"`] TEZ added into HDFS" >> $OSBDET_LOGFILE
}
remove_tezhdfssetup() {
  debug "hive3.remove_tezhdfssetup DEBUG [`date +"%Y-%m-%d %T"`] Removing TEZ from HDFS" >> $OSBDET_LOGFILE
  su - osbdet -c ". /$HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/start-dfs.sh" >> $OSBDET_LOGFILE 2>&1
  export HADOOP_USER_NAME=osbdet
  $HADOOP_HOME/bin/hdfs dfsadmin -safemode leave >> $OSBDET_LOGFILE 2>&1
  $HADOOP_HOME/bin/hdfs dfs -rm -r /apps/tez-0.9.2 >> $OSBDET_LOGFILE 2>&1
  su - osbdet -c ". /$HADOOP_HOME/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/stop-dfs.sh" >> $OSBDET_LOGFILE 2>&1
  debug "hive3.remove_tezhdfssetup DEBUG [`date +"%Y-%m-%d %T"`] TEZ removed from HDFS" >> $OSBDET_LOGFILE
}

initscript() {
  debug "hive3.initscript DEBUG [`date +"%Y-%m-%d %T"`] Installing the Hive 3 systemd script" >> $OSBDET_LOGFILE
  cp $SCRIPT_PATH/hiveserver.service /lib/systemd/system/hiveserver.service
  cp $SCRIPT_PATH/hiveserver2-start.sh $HIVE_HOME/bin
  chmod 644 /lib/systemd/system/hiveserver.service
  chown osbdet:osbdet $HIVE_HOME/bin/hiveserver2-start.sh
  systemctl daemon-reload
  debug "hive3.initscript DEBUG [`date +"%Y-%m-%d %T"`] Hive 3 systemd script installed" >> $OSBDET_LOGFILE
}
remove_initscript() {
  debug "hive3.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Removing the Hive 3 systemd script" >> $OSBDET_LOGFILE
  rm /lib/systemd/system/hiveserver.service
  systemctl daemon-reload
  debug "hive3.remove_initscript DEBUG [`date +"%Y-%m-%d %T"`] Hive 3 systemd script removed" >> $OSBDET_LOGFILE
}

userprofile() {
  debug "hive3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] Setting up user profile to run Hive 3" >> $OSBDET_LOGFILE
  echo >> /home/osbdet/.profile
  echo '# set HIVE_HOME and add its bin folder to the PATH' >> /home/osbdet/.profile
  echo 'export HIVE_HOME=/opt/hive3' >> /home/osbdet/.profile
  echo 'PATH="$PATH:$HIVE_HOME/bin"' >> /home/osbdet/.profile
  debug "hive3.userprofile DEBUG [`date +"%Y-%m-%d %T"`] User profile to run Hive 3 setup" >> $OSBDET_LOGFILE
}
remove_userprofile() {
  debug "hive3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Removing Hive 3 setup from user profile" >> $OSBDET_LOGFILE
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
  debug "hive3.remove_userprofile DEBUG [`date +"%Y-%m-%d %T"`] Hive 3 setup removed from user profile" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "hive3.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Get Hive 3 and extract it
  #   2. Set up environment variables for the rest of the installation process
  #   3. Copy Hadoop 3 configuration files
  #   4. Password-less ssh connections setup
  #   5. HDFS initialization
  #   6. Copy of scripts to operate Hadoop 3 (start and stop)
  #   7. Update of osdbet user profile to have access to Hadoop 3 binaries
  printf "  Installing module 'hive3' ... "
  getandextract
  setenvvars
  metastoreinit
  hadoopsetup
  tezinstall
  hadoop3_setenvvars
  tezhdfssetup
  initscript
  userprofile
  printf "[Done]\n"
  debug "hive3.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE

}

module_status() {
  if [ -d "/opt/hive3" ]
  then
    echo "Unit is installed [OK]"
    exit 0
  else
    echo "Unit is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "hive.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The uninstallation of this module consists on:
  #   1. Remove references to Hadoop 3 binaries from osbdet's profile
  #
  printf "  Uninstalling module 'hive3' ... "
  remove_userprofile
  remove_initscript
  hadoop3_setenvvars
  remove_tezhdfssetup
  remove_tezinstall
  remove_hadoopsetup
  removal
  printf "[Done]\n"
  debug "hive3.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE

}

usage() {
  echo Starting \'hive3\' module
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
  debug "hive3 DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the hive3 module" >> $OSBDET_LOGFILE
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
  debug "hive3 DEBUG [`date +"%Y-%m-%d %T"`] Activity with the hive3 module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  export SCRIPT_PATH=$(dirname $(realpath $0))
  main $*
fi
