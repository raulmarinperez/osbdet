#!/bin/bash

HADOOP_HOME=/opt/hadoop
HIVE_HOME=/opt/hive

. $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# set TEZ env vars
export TEZ_JARS=/opt/tez
export TEZ_CONF_DIR=/opt/tez/conf
export HADOOP_CLASSPATH=${TEZ_CONF_DIR}:${TEZ_JARS}/*:${TEZ_JARS}/lib/*


cd $HIVE_HOME
bin/hiveserver2
