#!/bin/bash
## Script to configure the Pig development env. for Linux.
## (Tested on Ubuntu 14.04)
## Author: chenxm
## Email: chenxm35@gmail.com

set -e

echo "Installing required libs to $DEFAULT_PIG_LIBS ... "
while true; do
    read -p "Do you wish to continue [y/n]: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

LOCAL_PIG=$HOME/.pig
DEFAULT_PIG_LIBS=$LOCAL_PIG/libs
PIGBOOTUP=$HOME/.pigbootup
THISHOME=`dirname $0`
mkdir -p $DEFAULT_PIG_LIBS

install_piggybank(){
    echo "Installing piggybank ..."
    while true; do
        read -p "Which hadoop are you using [1/2]: " hv
        case $hv in
            1 ) hadoopv=20;break;;
            2 ) hadoopv=23;break;;
            * ) echo "Please enter 1 (hadoop 1.X.Y) or 2 (hadoop 2.X.Y).";;
        esac
    done
    echo "Hadoop $hv configured ..."
    cp $THISHOME/libs/piggybank-$hadoopv.jar $DEFAULT_PIG_LIBS/piggybank.jar
}

install_piggybox(){
    echo "Installing piggybox ..."
    rm -rf $THISHOME/piggybox
    git clone git@github.com:caesar0301/piggybox.git $THISHOME/piggybox
    cd $THISHOME/piggybox && echo "Compiling ... " && mvn -q package
    UDFJAR=target/piggybox-*-with-dependencies.jar
    UDFPY=src/main/python/pyudf.py
    cp $UDFJAR $DEFAULT_PIG_LIBS/piggybox.jar
    cd -
}

install_datafu(){
    echo "Installing dataFu ..."
    SRC=datafu
    rm -rf $THISHOME/$SRC
    git clone git@github.com:apache/incubator-datafu.git $SRC
    cd $THISHOME/$SRC/ && ./gradlew clean install
    PIGPKG="datafu-pig/build/libs/"
    cp `find $PIGPKG -regextype posix-extended \
-regex ".*datafu-pig-([0-9]+\.)+[0-9]+(-SNAPSHOT)?\.jar$"` $DEFAULT_PIG_LIBS
    cd -
}

install_elephant-bird(){
    echo "Installing elephant-bird ..."
    # dependencies
    sudo apt-get install protobuf-compiler
    wget http://www.us.apache.org/dist/thrift/0.9.1/thrift-0.9.1.tar.gz
    tar zxf thrift-0.9.1.tar.gz
    cd thrift-0.9.1 && ./configure && make && sudo make install && cd ..
    # install
    rm -rf elephant-bird
    git clone git://github.com/kevinweil/elephant-bird.git elephant-bird
    cd $THISHOME/elephant-bird/pig/ && mvn -p package
    cp target/elephant-bird-*.jar $DEFAULT_PIG_LIBS/elephant-bird.jar
    cd -
}

download_utilities(){
    echo "Installing other utilities ..."
    # download avro
    wget -P $DEFAULT_PIG_LIBS -N http://www.us.apache.org/dist/avro/stable/java/avro-1.7.7.jar
    # download json-simple
    wget -P $DEFAULT_PIG_LIBS -N http://central.maven.org/maven2/com/googlecode/json-simple/json-simple/1.1.1/json-simple-1.1.1.jar
    # download other libs
    cp -r $THISHOME/libs/* $DEFAULT_PIG_LIBS/
    # clean duplicate jars
    rm -f $DEFAULT_PIG_LIBS/piggybank-2*.jar
}

configure_pigbootup(){
    ## backup .piggybootup
    echo "Configuraing .pigbootup ... "
    if [ -f $PIGBOOTUP ]; then
        echo "$PIGBOOTUP has existed. Backuped to '.pigboot_bak'"
        cp $PIGBOOTUP $PIGBOOTUP"_bak"
    fi
    ## update configurations
    touch $PIGBOOTUP
    echo "" >> $PIGBOOTUP
    echo "/*These are generated automatically to define preloaded commands of Pig.*/" >> $PIGBOOTUP
    echo "" >> $PIGBOOTUP
    ## echo "%default PIG_LIBS '/home/"`whoami`"/.pig/libs';" >> $PIGBOOTUP
    for file in `ls $DEFAULT_PIG_LIBS/*.jar`; do
        echo "REGISTER $file;" >> $PIGBOOTUP
    done
}

install_piggybank
install_piggybox
install_datafu
#install_elephant-bird
download_utilities
configure_pigbootup

echo "Done!"
