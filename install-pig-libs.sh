#!/bin/bash
## Script to configure the Pig development env. for Linux.
## (Tested on Ubuntu 14.04)
## Author: chenxm
## Email: chenxm35@gmail.com
# set -e

##############################################################################
##
##  Start up script for Ubuntu
##
##############################################################################

LOCAL_PIG=/home/`whoami`/.pig
DEFAULT_PIG_LIBS=$LOCAL_PIG/libs
PIGBOOTUP=/home/`whoami`/.pigbootup
THISHOME=`dirname $0`

echo "Installing required libs to $DEFAULT_PIG_LIBS ... "
while true; do
    read -p "Do you wish to continue [y/n]: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

## Make installed folders
mkdir -p $DEFAULT_PIG_LIBS

## Install piggybank.
while true; do
    read -p "Which hadoop are you using [20/23]: " hv
    case $hv in
        20 ) hadoopv=20;break;;
        23 ) hadoopv=23;break;;
        * ) echo "Please enter 20 (hadoop 0.20) or 23 (hadoop 0.23).";;
    esac
done
echo "Hadoop version $hadoopv selected."
cp $THISHOME/libs/piggybank-$hadoopv.jar $DEFAULT_PIG_LIBS/piggybank.jar

## Download avro.jar
wget -P $DEFAULT_PIG_LIBS -N http://www.us.apache.org/dist/avro/stable/java/avro-1.7.7.jar
wget -P $DEFAULT_PIG_LIBS -N http://central.maven.org/maven2/com/googlecode/json-simple/json-simple/1.1.1/json-simple-1.1.1.jar

## Clone and install piggybox from OMNILAB.
rm -rf $THISHOME/piggybox
git clone git@github.com:caesar0301/piggybox.git $THISHOME/piggybox
cd $THISHOME/piggybox && echo "Compiling ... " && mvn package
UDFJAR=target/piggybox-*-with-dependencies.jar
UDFPY=src/main/python/pyudf.py
cp $UDFJAR $DEFAULT_PIG_LIBS/piggybox.jar
# cp $UDFPY $DEFAULT_PIG_LIBS/pyudf.py
cd -

## Install Apache DataFu
rm -rf $THISHOME/datafu
git clone git://git.apache.org/incubator-datafu.git datafu
cd $THISHOME/datafu && ./gradlew assemble
cp `find datafu-pig/build/libs/ -regextype posix-extended -regex ".*datafu-pig-([0-9]+\.)+[0-9]+\.jar$"` $DEFAULT_PIG_LIBS
cd ..

## Install elephant-bird from Twitter
## Dependencies
#sudo apt-get install protobuf-compiler
#wget http://www.us.apache.org/dist/thrift/0.9.1/thrift-0.9.1.tar.gz
#tar zxf thrift-0.9.1.tar.gz
#cd thrift-0.9.1 && ./configure && make && sudo make install && cd ..
## Now install EB
#rm -rf elephant-bird
#git clone git://github.com/kevinweil/elephant-bird.git
#cd $THISHOME/elephant-bird/pig/ && mvn package
#cp target/elephant-bird-*.jar $DEFAULT_PIG_LIBS/elephant-bird.jar
#cd -

## Install other libraries
cp -r $THISHOME/libs/* $DEFAULT_PIG_LIBS/
## Remove duplicate libs
rm -rf $DEFAULT_PIG_LIBS/piggybank-2*.jar

## Backup .piggybootup
echo "Configuraing .pigbootup ... "
if [ -f $PIGBOOTUP ]; then
    echo "$PIGBOOTUP has existed. Backuped to '.pigboot_bak'"
    cp $PIGBOOTUP $PIGBOOTUP"_bak"
fi

## Update configurations
touch $PIGBOOTUP
echo "/* This file is generated automatically to define preloaded" > $PIGBOOTUP
echo "commands of Pig. */" >> $PIGBOOTUP
echo "" >> $PIGBOOTUP
## echo "%default PIG_LIBS '/home/"`whoami`"/.pig/libs';" >> $PIGBOOTUP
for file in `ls $DEFAULT_PIG_LIBS/*.jar`; do
    echo "REGISTER $file;" >> $PIGBOOTUP
done
# for file in `ls $DEFAULT_PIG_LIBS/*.py`; do
#     echo "REGISTER $file using jython as pyudf;" >> $PIGBOOTUP
# done

echo "Done!"
