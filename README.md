# Open Source Big Data Educational Toolkit (OSBDET)
OSBDET is a test environment creation tool which facilitates the creation of sandboxes containing a bunch of open source technologies all together. These tests environments are targeting people who want to take their first steps with Big Data technologies easily.

The following are some of the Big Data frameworks that OSBDET is able to bring into a test environment:

- Hadoop 3
- Hive 3
- Spark 3
- Kafka 2
- ...

OSBDET's architecture encourages the extension of this toolkit to introduce new frameworks with very little effort.
## How to use OSBDET
OSBDET can be controlled with one single script, `osbdet-builder.sh`, which brings the following options:
```root@osbdet:~/osbdet# ./osbdet_builder.sh
Usage: osbdet_builder.sh [OPTION] [comma separated list of modules]

Available options for mounter:
  status              display the current status of OSBDET's modules
  modules             list available modules
  build               build environment by installing available modules
  remove              remove installed modules from current environment
```
The file `osbdet.log` tracks all the steps taken by the script; tail this file while building or removing modules to get all the information about the process.
### Listing available modules
The `modules` option list all the available modules:
```
root@osbdet:~/osbdet# ./osbdet_builder.sh modules
These are the modules available in OSBDET vS21R1:
  - mongodb44: MongoDB 4.4 installation, depends on: foundation
  - hadoop3: Hadoop 3 installation, depends on: foundation
  - mariadb: MariaDB installation, depends on: foundation
  - truckssim: Truck fleet simulator, depends on: foundation
  - kafka2: Kafka 2 installation, depends on: foundation
  - hive3: Hive 3 installation, depends on: foundation,hadoop3
  - nifi: NiFi installation, depends on: foundation
  - jupyter: Jupyter Notebook installation, depends on: foundation
  - superset: Superset installation, depends on: foundation
  - foundation: Configurations and dependencies to satisfy the installation of other modules, depends on: no_dependencies
  - spark3: Spark 3 installation, depends on: foundation
```
### Displaying the status of available modules
The `status` option list all the available modules:
```
root@osbdet:~/osbdet# ./osbdet_builder.sh status
The folowing list shows the status of all available modules:
  - mongodb44: Module is not installed [KO]
  - hadoop3: Module is not installed [KO]
  - mariadb: Module is installed [OK]
  - truckssim: Module is not installed [KO]
  - kafka2: Module is installed [OK]
  - hive3: Module is not installed [KO]
  - nifi: Module is not installed [KO]
  - jupyter: Module is installed [OK]
  - superset: Module is installed [OK]
  - foundation: Module is installed [OK]
  - spark3: Module is installed [OK]
```
### Building modules
The `build` option tells OSBDET to install the modules provided as arguments:
```
root@osbdet:~/osbdet# ./osbdet_builder.sh build mariadb
Building some modules into OSBDET:
[install_module] Skipping 'foundation'  module is already installed
  Installing module 'mariadb' ... [Done]
```
### Removing modules
The `remove` option tells OSBDET to remove the modules provided as arguments:
```
root@osbdet:~/osbdet# ./osbdet_builder.sh remove mariadb
Removing modules from OSBDET:
  Uninstalling module 'mariadb' ... [Done]
```
