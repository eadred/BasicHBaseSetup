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

echo "Checkpoint: Provisioning..."

echo "Checkpoint: Installing base packages"
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java8-installer
sudo apt-get install -y ssh
sudo apt-get install -y rsync

pushd /usr/local

echo "Checkpoint: Installing hadoop"
sudo wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
sudo tar xzf hadoop-2.7.3.tar.gz
sudo mv hadoop-2.7.3 hadoop
sudo rm hadoop-2.7.3.tar.gz

echo "Checkpoint: Installing hbase"
sudo wget http://archive.apache.org/dist/hbase/1.2.3/hbase-1.2.3-bin.tar.gz
sudo tar xzf hbase-1.2.3-bin.tar.gz
sudo mv hbase-1.2.3 hbase
sudo rm hbase-1.2.3-bin.tar.gz

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
# Run . ~/.bashrc to reload these

echo "Checkpoint: Creating conf directory sym links"
sudo mkdir /etc/hadoop
sudo ln -s /usr/local/hadoop/etc/hadoop /etc/hadoop/conf
sudo mkdir /etc/hbase
sudo ln -s /usr/local/hbase/conf /etc/hbase/conf

echo "Checkpoint: Updating hadoop core-site.xml settings"
sudo cp /etc/hadoop/conf/core-site.xml /etc/hadoop/conf/core-site.xml.orig
cat $SCRIPTDIR/core-site.xml \
  | sed "s/{StorageAccount}/$STORAGE_ACCT/g" \
  | sed "s/{AccessKey}/$STORAGE_ACCT_KEY/g" \
  | sed "s/{DefaultFsContainer}/$DEF_FS_CNT/g" \
  | sed "s/{ResultsContainer}/$RESULTS_CNT/g" \
  | sudo tee /etc/hadoop/conf/core-site.xml

echo "Checkpoint: Updating hbase-site.xml settings"
sudo cp /etc/hbase/conf/hbase-site.xml /etc/hbase/conf/hbase-site.xml.orig
cat $SCRIPTDIR/hbase-site.xml \
  | sed "s/{StorageAccount}/$STORAGE_ACCT/g" \
  | sed "s/{AccessKey}/$STORAGE_ACCT_KEY/g" \
  | sed "s/{DefaultFsContainer}/$DEF_FS_CNT/g" \
  | sed "s/{ResultsContainer}/$RESULTS_CNT/g" \
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

echo "Checkpoint: Done"
