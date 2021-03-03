#!/bin/bash

HADOOP_HOME=/opt/hadoop3
HIVE_HOME=/opt/hive3

. $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# set TEZ env vars
export TEZ_JARS=/opt/hive3/tez
export TEZ_CONF_DIR=/opt/hive3/tez/conf
export HADOOP_CLASSPATH=${TEZ_CONF_DIR}:${TEZ_JARS}/*:${TEZ_JARS}/lib/*


cd $HIVE_HOME
bin/hiveserver2
