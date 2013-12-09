#!/bin/bash
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CWD/base.sh

#echo "Installing curl"
#apt-get install -y curl

set +e
stop elastic

echo "Checking java install"
which java >/dev/null
if [ $? -ne 0 ]; then
   set -e
   echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
   add-apt-repository -y ppa:webupd8team/java
   apt-get update
   apt-get install -y oracle-java7-installer
fi

set -e

ELASTIC_HOME=$AMCAT_ROOT/elastic

echo "Checking elastic files in $ELASTIC_HOME"
mkdir -p $ELASTIC_HOME
cd $ELASTIC_HOME
if [ ! -d $ELASTIC_HOME/elasticsearch-0.90.5 ]; then
    curl https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.5.tar.gz  | tar xz
    wget http://amcat.vu.nl/plain/hitcount.jar
    elasticsearch-0.90.5/bin/plugin -install elasticsearch/elasticsearch-lang-python/1.2.0
    elasticsearch-0.90.5/bin/plugin -install mobz/elasticsearch-head
    elasticsearch-0.90.5/bin/plugin -install elasticsearch/elasticsearch-analysis-icu/1.12.0
fi


SRC=$CWD/elastic.conf-dist
TRG=/etc/init/elastic.conf
echo "Checking upstart script at $TRG"
if [ ! -e $TRG ]; then
    echo "Creating upstart script $TRG from $SRC"
    sed -e "s#__ES_HOME__#$ELASTIC_HOME/elasticsearch-0.90.5#" -e "s#__HITCOUNT_JAR__#$ELASTIC_HOME/hitcount.jar#" < $SRC > $TRG
    chmod 644 $TRG
fi
start elastic
