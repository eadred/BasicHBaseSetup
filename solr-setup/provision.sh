SCRIPTDIR=$(dirname $0)

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

echo Storage account is $STORAGE_ACCT
echo Storage account key is $STORAGE_ACCT_KEY
echo Default file system container is $DEF_FS_CNT

echo "Checkpoint: Provisioning..."


echo "Checkpoint: Installing base packages"
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | sudo debconf-set-selections
sudo apt-get install -y oracle-java8-installer
sudo apt-get install -y ssh
sudo apt-get install -y rsync

pushd /usr/local

echo "Checkpoint: Fetching Solr"
sudo wget http://apache.mirror.anlx.net/lucene/solr/6.3.0/solr-6.3.0.tgz
sudo tar xzf solr-6.3.0.tgz
sudo mv solr-6.3.0 solr
sudo rm solr-6.3.0.tgz

echo "Checkpoint: Fetching Hadoop jars"
sudo wget http://apache.mirror.anlx.net/hadoop/common/hadoop-2.7.2/hadoop-2.7.2.tar.gz
sudo tar xzf hadoop-2.7.2.tar.gz
sudo mv hadoop-2.7.2 hadoop
sudo rm hadoop-2.7.2.tar.gz

pushd hadoop/etc/hadoop
sudo cp mapred-site.xml.template mapred-site.xml
sudo mv core-site.xml core-site.xml.orig
cat $SCRIPTDIR/core-site.xml \
  | sed "s/{StorageAccount}/$STORAGE_ACCT/g" \
  | sed "s/{AccessKey}/$STORAGE_ACCT_KEY/g" \
  | sed "s/{DefaultFsContainer}/$DEF_FS_CNT/g" \
  | sudo tee ./core-site.xml

echo 'export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-azure-2.7.2.jar:/usr/local/hadoop/share/hadoop/tools/lib/azure-storage-2.0.0.jar' \
  | sudo tee -a ./hadoop-env.sh
  
popd


pushd solr/server

echo "Checkpoint: Updating Solr configs"
pushd solr/configsets/data_driven_schema_configs/conf

sudo mv solrconfig.xml solrconfig.xml.orig
cat solrconfig.xml.orig \
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
    <lib path="\/usr\/local\/hadoop\/share\/hadoop\/tools\/lib\/hadoop-azure-2.7.2.jar" \/>' \
  | sudo tee ./solrconfig.xml

popd

echo "Checkpoint: Copying dependencies"

pushd solr-webapp/webapp/WEB-INF/lib

sudo rm solr-core-6.3.0.jar
sudo cp $SCRIPTDIR/solr-core-6.3.0.jar .

sudo cp /usr/local/hadoop/share/hadoop/tools/lib/azure-storage-2.0.0.jar .
sudo cp /usr/local/hadoop/share/hadoop/tools/lib/hadoop-azure-2.7.2.jar .
sudo cp /usr/local/hadoop/share/hadoop/tools/lib/jetty-util-6.1.26.jar .
popd

pushd ../dist
sudo rm solr-core-6.3.0.jar
sudo cp $SCRIPTDIR/solr-core-6.3.0.jar .
popd

popd



sudo mkdir /var/solr
sudo mkdir /var/solr/logs
sudo chmod a+w /var/solr/logs
echo HADOOP_CLASSPATH=$(/usr/local/hadoop/bin/hadoop classpath) | sudo tee -a solr/bin/solr.in.sh
echo 'CLASSPATH=$CLASSPATH:$HADOOP_CLASSPATH' | sudo tee -a solr/bin/solr.in.sh
echo SOLR_LOGS_DIR=/var/solr/logs | sudo tee -a solr/bin/solr.in.sh


if [ "$IS_MASTER" ]; then
  echo "Checkpoint: Fetching Zookeeper"
  sudo wget http://apache.mirror.anlx.net/zookeeper/zookeeper-3.4.9/zookeeper-3.4.9.tar.gz
  sudo tar xzf zookeeper-3.4.9.tar.gz
  sudo mv zookeeper-3.4.9 zookeeper
  sudo rm zookeeper-3.4.9.tar.gz

  sudo mkdir /var/lib/zookeeper

  pushd zookeeper/conf
  cat zoo_sample.cfg \
    | sed "s/dataDir=.*$/dataDir=\/var\/lib\/zookeeper/" \
    | sudo tee ./zoo.cfg
  popd
fi

popd

echo "Checkpoint: Exporting environment variables"
pushd /etc/profile.d
sudo touch env_vars.sh
sudo chmod a+x env_vars.sh
echo export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre | sudo tee -a env_vars.sh
popd
