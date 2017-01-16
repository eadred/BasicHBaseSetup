SCRIPTDIR=/vagrant

ROOT_DIR=/usr/local
HBASE_INDEXER_DIR=$ROOT_DIR/hbase-indexer
SOLR_DIR=$ROOT_DIR/solr

pushd $ROOT_DIR

echo "Checkpoint: Start Hbase"
pushd hbase/bin
sudo ./start-hbase.sh
popd

echo "Checkpoint: Start hbase-indexer"
pushd hbase-indexer/bin
sudo ./hbase-indexer server &
popd

echo "Checkpoint: Start solr in cloud mode"
pushd solr/bin
sudo ./solr start -e cloud -noprompt
popd

popd

echo "Checkpoint: create Hbase tables"
hbase shell ./create-tables.txt

echo "Checkpoint: set REPLICATION_SCOPE to 1 for 'tweets' table"
hbase shell ./switch_replication_on.txt

echo "Checkpoint: add tweets indexer"
pushd $HBASE_INDEXER_DIR
sudo mkdir indexers
sudo cp $SCRIPTDIR/tweets-indexer.xml indexers/tweets.xml

pushd bin
sudo ./hbase-indexer add-indexer -n tweets -c ../indexers/tweets.xml -cp solr.zk=localhost:2181 -cp solr.collection=gettingstarted
popd

popd
