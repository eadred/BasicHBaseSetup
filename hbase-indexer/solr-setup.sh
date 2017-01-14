if [ -z "$STORAGE_ACCT" ]; then
  echo "STORAGE_ACCT (storage account) not specified"
  exit -1
fi

if [ -z "$STORAGE_ACCT_KEY" ]; then
  echo "STORAGE_ACCT_KEY (storage account key) not specified"
  exit -1
fi

if [ -z "$DEF_FS_CNT" ]; then
  echo "DEF_FS_CNT (default file system container) not specified"
  exit -1
fi

if [ -z "$RESULTS_CNT" ]; then
  echo "RESULTS_CNT (results container) not specified"
  exit -1
fi

echo Storage account is $STORAGE_ACCT
echo Storage account key is $STORAGE_ACCT_KEY
echo Default file system container is $DEF_FS_CNT



SCRIPTDIR=/vagrant

# Some useful paths
ROOT_DIR=/usr/local
SOLR_SERVER_DIR=$ROOT_DIR/solr/server
SOLR_CONF_DIR=$SOLR_SERVER_DIR/solr/configsets/data_driven_schema_configs/conf
SOLR_WEBAPP_LIB_DIR=$SOLR_SERVER_DIR/solr-webapp/webapp/WEB-INF/lib
SOLR_BIN_DIR=$ROOT_DIR/solr/bin
HADOOP_CONF_DIR=$ROOT_DIR/hadoop/etc/hadoop
HADOOP_TOOLS_LIB_DIR=$ROOT_DIR/hadoop/share/hadoop/tools/lib

echo "Checkpoint: Fetching Solr"
sudo wget http://apache.mirror.anlx.net/lucene/solr/5.5.3/solr-5.5.3.tgz
sudo tar xzf solr-5.5.3.tgz
sudo mv solr-5.5.3 $ROOT_DIR/solr
sudo rm solr-5.5.3.tgz

echo "Checkpoint: Updating solrconfig.xml"
sudo mv $SOLR_CONF_DIR/solrconfig.xml $SOLR_CONF_DIR/solrconfig.xml.orig
cat $SOLR_CONF_DIR/solrconfig.xml.orig \
  | sed "s/{solr.lock.type:.*}/{solr.lock.type:hdfs}/" \
  | sed 's/{solr.directoryFactory:solr.NRTCachingDirectoryFactory}"\/>/{solr.directoryFactory:solr.HdfsDirectoryFactory}">/' \
  | sed '/{solr.directoryFactory:solr.HdfsDirectoryFactory}">/a\
    <str name="solr.hdfs.confdir">{HdfsConfDir}<\/str>\
    <str name="solr.hdfs.home">wasb:\/\/{DefaultFsContainer}@{StorageAccount}.blob.core.windows.net\/solr<\/str>\
  <\/directoryFactory>' \
  | sed "s/{StorageAccount}/$STORAGE_ACCT/" \
  | sed "s/{DefaultFsContainer}/$DEF_FS_CNT/" \
  | sed "s/{HdfsConfDir}/\/usr\/local\/hadoop\/etc\/hadoop/" \
  | sed '/<lib.*solr-velocity/a\
    <lib dir="\/usr\/local\/hadoop\/share\/hadoop\/common\/lib" regex=".*\.jar" />\
    <lib dir="\/usr\/local\/hadoop\/share\/hadoop\/common" regex=".*\.jar" />\
    <lib path="\/usr\/local\/hadoop\/share\/hadoop\/tools\/lib\/azure-storage-2.0.0.jar" \/>\
    <lib path="\/usr\/local\/hadoop\/share\/hadoop\/tools\/lib\/hadoop-azure-2.6.0.2.2.5.2-7.jar" \/>' \
  | sed "s@<autoCommit>@<autoCommit>\n\t<maxDocs>1000</maxDocs>@" \
  | sudo tee $SOLR_CONF_DIR/solrconfig.xml

echo "Checkpoint: Updating Solr's zookeeper config"
sudo sed -i "s|# clientPort=2181|clientPort=2181|" $SOLR_SERVER_DIR/solr/zoo.cfg

echo "Checkpoint: Copying Solr dependencies"

sudo cp $SCRIPTDIR/solr-core-5.5.3.jar $SOLR_WEBAPP_LIB_DIR
sudo cp $HADOOP_TOOLS_LIB_DIR/azure-storage-2.0.0.jar $SOLR_WEBAPP_LIB_DIR
sudo cp $HADOOP_TOOLS_LIB_DIR/hadoop-azure-2.6.0.2.2.5.2-7.jar $SOLR_WEBAPP_LIB_DIR
sudo cp $HADOOP_TOOLS_LIB_DIR/jetty-util-6.1.26.jar $SOLR_WEBAPP_LIB_DIR

sudo rm $SOLR_SERVER_DIR/../dist/solr-core-5.5.3.jar
sudo cp $SCRIPTDIR/solr-core-5.5.3.jar $SOLR_SERVER_DIR/../dist

echo "Checkpoint: Updating misc Solr configuration"
sudo mkdir /var/solr
sudo mkdir /var/solr/logs
sudo chmod a+w /var/solr/logs
echo HADOOP_CLASSPATH=$(/usr/local/hadoop/bin/hadoop classpath) | sudo tee -a $SOLR_BIN_DIR/solr.in.sh
echo 'CLASSPATH=$CLASSPATH:$HADOOP_CLASSPATH' | sudo tee -a $SOLR_BIN_DIR/solr.in.sh
echo SOLR_LOGS_DIR=/var/solr/logs | sudo tee -a $SOLR_BIN_DIR/solr.in.sh


