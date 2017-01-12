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

if [ -z "$RESULTS_CNT" ]; then
  echo "RESULTS_CNT (results container) not specified"
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

echo "Checkpoint: Fetching Hadoop jars"
sudo wget http://apache.mirror.anlx.net/hadoop/common/hadoop-2.5.2/hadoop-2.5.2.tar.gz
sudo tar xzf hadoop-2.5.2.tar.gz
sudo mv hadoop-2.5.2 hadoop
sudo rm hadoop-2.5.2.tar.gz

echo "Checkpoint: Fetching Hbase jars"
sudo wget http://archive.apache.org/dist/hbase/1.1.2/hbase-1.1.2-bin.tar.gz
sudo tar xzf hbase-1.1.2-bin.tar.gz
sudo mv hbase-1.1.2 hbase
sudo rm hbase-1.1.2-bin.tar.gz

popd

echo "Checkpoint: Removing version numbers from hbase lib jars"
shopt -s extglob
pushd /usr/local/hbase/lib
for i in *-*([0-9]).*([0-9]).*([0-9]).jar
do
  sudo cp "$i" "$(echo "$i" | sed 's/-[0-9]*\.[0-9]*\.[0-9]*\.jar$/\.jar/')"
done
popd

echo "Checkpoint: Exporting environment variables"
echo export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre >> ~/.bashrc
echo export HADOOP_HOME=/usr/local/hadoop >> ~/.bashrc
echo export HBASE_HOME=/usr/local/hbase >> ~/.bashrc
echo export HBASE_LIB_PATH="$"HBASE_HOME/lib >> ~/.bashrc
echo export PATH="$"PATH:"$"HADOOP_HOME/bin:"$"HBASE_HOME/bin >> ~/.bashrc
echo export HADOOP_CLASSPATH="/usr/local/hadoop/share/hadoop/tools/lib/*" >> ~/.bashrc

echo "Checkpoint: Creating conf directory sym links"
sudo mkdir /etc/hadoop
sudo ln -s /usr/local/hadoop/etc/hadoop /etc/hadoop/conf
sudo mkdir /etc/hbase
sudo ln -s /usr/local/hbase/conf /etc/hbase/conf

echo "Checkpoint: Updating hadoop core-site.xml settings"
sudo cp /etc/hadoop/conf/core-site.xml /etc/hadoop/conf/core-site.xml.orig
cat /vagrant/core-site.xml \
  | sed "s@{StorageAccount}@$STORAGE_ACCT@g" \
  | sed "s@{AccessKey}@$STORAGE_ACCT_KEY@g" \
  | sed "s@{DefaultFsContainer}@$DEF_FS_CNT@g" \
  | sed "s@{ResultsContainer}@$RESULTS_CNT@g" \
  | sudo tee /etc/hadoop/conf/core-site.xml

pushd /usr/local/hadoop/etc/hadoop
echo 'export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-azure-2.6.0.2.2.5.2-7.jar:/usr/local/hadoop/share/hadoop/tools/lib/azure-storage-2.0.0.jar' \
  | sudo tee -a ./hadoop-env.sh
  
popd

echo "Checkpoint: Updating hbase-site.xml settings"
sudo cp /etc/hbase/conf/hbase-site.xml /etc/hbase/conf/hbase-site.xml.orig
cat /vagrant/hbase-site.xml \
  | sed "s@{StorageAccount}@$STORAGE_ACCT@g" \
  | sed "s@{AccessKey}@$STORAGE_ACCT_KEY@g" \
  | sed "s@{DefaultFsContainer}@$DEF_FS_CNT@g" \
  | sed "s@{ResultsContainer}@$RESULTS_CNT@g" \
  | sudo tee /etc/hbase/conf/hbase-site.xml

echo "Checkpoint: Updating hbase-env.sh settings"
sudo sed -i \
  -e 's|.*export JAVA_HOME=.*$|export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre|' \
  -e 's|.*export HBASE_CLASSPATH=.*$|export HBASE_CLASSPATH="/usr/local/hadoop/share/hadoop/tools/lib/*"|' \
  -e 's|.*export HBASE_OPTS="\(.*\)"|export HBASE_OPTS="\1 -Djava.net.preferIPv4Stack=true"|' \
  /etc/hbase/conf/hbase-env.sh


echo "Checkpoint: Configuring host name related settings"
ip=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
sudo sed -i "s/localhost/$(hostname)/" /etc/hbase/conf/regionservers
echo -e "\n# HBase related configuration\n$ip $(hostname)" | sudo tee -a /etc/hosts
sudo sed -i "s/{HostName}/$(hostname)/" /etc/hbase/conf/hbase-site.xml


pushd /usr/local
echo "Checkpoint: Fetching Solr"
sudo wget http://apache.mirror.anlx.net/lucene/solr/5.5.3/solr-5.5.3.tgz
sudo tar xzf solr-5.5.3.tgz
sudo mv solr-5.5.3 solr
sudo rm solr-5.5.3.tgz

echo "Checkpoint: Updating Solr configs"
pushd solr/server/solr/configsets/data_driven_schema_configs/conf
sudo cp solrconfig.xml.orig solrconfig.xml
sudo sed -i 's|<autoCommit>|<autoCommit>\n\t<maxDocs>1000</maxDocs>|' solrconfig.xml
popd

sudo mkdir /var/solr
sudo mkdir /var/solr/logs
sudo chmod a+w /var/solr/logs
echo HADOOP_CLASSPATH=$(/usr/local/hadoop/bin/hadoop classpath) | sudo tee -a solr/bin/solr.in.sh
echo 'CLASSPATH=$CLASSPATH:$HADOOP_CLASSPATH' | sudo tee -a solr/bin/solr.in.sh
echo SOLR_LOGS_DIR=/var/solr/logs | sudo tee -a solr/bin/solr.in.sh

echo "Checkpoint: Start Solr in cloud mode"
pushd solr/bin
sudo ./solr start -e cloud -noprompt
popd

popd


echo "Checkpoint: Exporting environment variables"
pushd /etc/profile.d
sudo touch env_vars.sh
sudo chmod a+x env_vars.sh
echo export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre | sudo tee -a env_vars.sh
popd


echo "Checkpoint: Installing git and maven"
sudo apt-get install -y git
sudo apt-get install -y maven

echo "Checkpoint: Fetching hbase-indexer"
pushd /usr/local
sudo git clone https://github.com/lucidworks/hbase-indexer.git hbase-indexer

pushd hbase-indexer
sudo mvn clean package -DskipTests -Dhbase.api=1.1.2

echo "Checkpoint: Configuring hbase-indexer"
pushd conf
sudo cp hbase-indexer-site.xml hbase-indexer-site.xml.orig
cat /vagrant/hbase-indexer-site.xml \
  | sed "s/{HostName}/$(hostname)/g" \
  | sudo tee hbase-indexer-site.xml
sudo cp /usr/local/hbase/conf/hbase-site.xml hbase-site.xml
popd

popd

echo "Checkpoint: Copying hbase-indexer jars"
sudo cp hbase-indexer/hbase-sep/hbase-sep-api/target/hbase-sep-api-*.jar hbase/lib
sudo cp hbase-indexer/hbase-sep/hbase-sep-impl/target/hbase-sep-impl-common-*.jar hbase/lib
sudo cp hbase-indexer/hbase-sep/hbase-sep-impl-1.1.2/target/hbase-sep-impl-*-hbase1.1.2.jar hbase/lib
sudo cp hbase-indexer/hbase-sep/hbase-sep-tools/target/hbase-sep-tools-*.jar hbase/lib

echo "Checkpoint: Start Hbase"
pushd hbase/bin
sudo ./start-hbase.sh
popd

echo "Checkpoint: Start Hbase indexer Daemon"
pushd hbase-indexer/bin
sudo ./hbase-indexer server &
popd

popd
