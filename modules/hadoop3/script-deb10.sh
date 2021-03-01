#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""

# Aux functions
_hadoop3_getandextract(){
  wget http://apache.rediris.es/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz \
       -O /opt/hadoop-3.2.1.tar.gz
  echo "    Hadoop 3.2.1 download [Done]"

  tar zxf /opt/hadoop-3.2.1.tar.gz -C /opt
  rm /opt/hadoop-3.2.1.tar.gz
  ln -s /opt/hadoop-3.2.1 /opt/hadoop
  chown -R osbdet:osbdet /opt/hadoop*
  chmod +x /opt/hadoop/etc/hadoop/*-env.sh
}
_hadoop3_removal(){
  rm -rf /opt/hadoop-3.2.1
  rm /opt/hadoop
}

_hadoop3_setenvvars(){
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

_hadoop3_configfilessetup(){
  sed -i '/^# export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64/\nexport HADOOP_HOME=/opt/hadoop\n:' \
         $HADOOP_HOME/etc/hadoop/hadoop-env.sh
  sed -i '/^# export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
  cp $SCRIPT_PATH/core-site.xml.template $HADOOP_HOME/etc/hadoop/core-site.xml.template
  cp $SCRIPT_PATH/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
  cp $SCRIPT_PATH/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
  cp $SCRIPT_PATH/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
  chown osbdet:osbdet $HADOOP_HOME/etc/hadoop/core-site.xml.template $HADOOP_HOME/etc/hadoop/hdfs-site.xml \
                      $HADOOP_HOME/etc/hadoop/mapred-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
}

_hadoop3_sshsetup(){
  echo -e 'y\n' | ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key > /dev/null
  echo -e 'y\n' | ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key > /dev/null
  su - osbdet -c 'echo -e "y\n" | ssh-keygen -q -N "" -t rsa -f /home/osbdet/.ssh/id_rsa'
  su - osbdet -c 'cp /home/osbdet/.ssh/id_rsa.pub /home/osbdet/.ssh/authorized_keys'
  cp $SCRIPT_PATH/ssh_config /home/osbdet/.ssh/config
  chmod 600 /home/osbdet/.ssh/config
  chown osbdet:osbdet /home/osbdet/.ssh/config
}
_hadoop3_remove_sshsetup(){
  rm /etc/ssh/ssh_host_dsa_key*
  rm /etc/ssh/ssh_host_rsa_key*
  rm -rf /home/osbdet/.ssh
}

_hadoop3_hdfsinit(){
  mkdir -p /data/hdfs/namenode
  mkdir -p /data/hdfs/datanode
  chown osbdet:osbdet -R /data
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs namenode -format'
  sed s/HOSTNAME/localhost/ $HADOOP_HOME/etc/hadoop/core-site.xml.template > $HADOOP_HOME/etc/hadoop/core-site.xml
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/start-dfs.sh'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 755 /'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/osbdet'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /user'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 755 /user'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chmod 777 /tmp'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /tmp'
  su - osbdet -c '. /opt/hadoop/etc/hadoop/hadoop-env.sh; $HADOOP_HOME/sbin/stop-dfs.sh'
}
_hadoop3_remove_hdfsinit(){
  rm -rf /data
}

_hadoop3_scriptscopy(){
  mkdir -p /home/osbdet/bin
  cp $SCRIPT_PATH/hadoop-start.sh /home/osbdet/bin
  cp $SCRIPT_PATH/hadoop-stop.sh /home/osbdet/bin
  chown -R osbdet:osbdet /home/osbdet/bin
}
_hadoop3_remove_scriptscopy(){
  rm /home/osbdet/bin/hadoop-start.sh
  rm /home/osbdet/bin/hadoop-stop.sh
  # rmdir only removes empty folders (hide stderr output)
  rmdir /home/osbdet/bin 2> /dev/null
}

_hadoop3_userprofile(){
  echo >> /home/osbdet/.profile
  echo '# set HADOOP_HOME and add its bin folder to the PATH' >> /home/osbdet/.profile
  echo 'export HADOOP_HOME=/opt/hadoop' >> /home/osbdet/.profile
  echo 'PATH="$PATH:$HADOOP_HOME/bin"' >> /home/osbdet/.profile
}
_hadoop3_remove_userprofile(){
  # remove the break line before the user profile setup for Hadoop
  #   - https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern
  #   - https://unix.stackexchange.com/questions/29906/delete-range-of-lines-above-pattern-with-sed-or-awk
  tac /home/osbdet/.profile > /home/osbdet/.eliforp
  sed -i '/^# set HADOOP.*/{n;d}' /home/osbdet/.eliforp

  rm /home/osbdet/.profile
  tac /home/osbdet/.eliforp > /home/osbdet/.profile
  chown osbdet:osbdet /home/osbdet/.profile

  # remove user profile setup for Hadoop
  sed -i '/^# set HADOOP.*/,+3d' /home/osbdet/.profile
  rm -f /home/osbdet/.eliforp
}

# Primary functions
#
unit_install(){
  echo Starting Hadoop 3 deployment...

  #_hadoop3_getandextract
  #echo "    Hadoop 3.2.1 extraction and initial setup [Done]"
  #_hadoop3_setenvvars
  #_hadoop3_configfilessetup
  #echo "    Configuration files adding and edition [Done]"
  #_hadoop3_sshsetup
  #echo "    SSH password-less authentication setup [Done]"

  #_hadoop3_hdfsinit
  #echo "    HDFS initialization [Done]"
  #_hadoop3_scriptscopy
  #echo "    Hadoop util scripts copy [Done]"

  #_hadoop3_userprofile
  #echo "    User's environment variables setup [Done]"
}

unit_status() {
  if [ -L "/opt/hadoop" ]
  then
    echo "Unit is installed [OK]"
    exit 0
  else
    echo "Unit is not installed [KO]"
    exit 1
  fi
}

unit_uninstall(){
  echo Starting hadoop3_uninstall...

  _hadoop3_remove_userprofile
  echo "    User's environment variables removal [Done]"

  _hadoop3_remove_scriptscopy
  echo "    Hadoop util scripts removal [Done]"
  _hadoop3_remove_hdfsinit
  echo "    HDFS initialization removal [Done]"

  _hadoop3_remove_sshsetup
  echo "    SSH password-less authentication setup removal [Done]"
  _hadoop3_removal
  echo "    Hadoop 3.2.1 removal [Done]"
}

usage() {
  echo Starting \'hadoop3\' unit
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
