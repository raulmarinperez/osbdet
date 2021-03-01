#!/bin/bash

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
export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/                                                                                      

. $HADOOP_HOME/etc/hadoop/hadoop-env.sh
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh
$HADOOP_HOME/bin/mapred --daemon start historyserver