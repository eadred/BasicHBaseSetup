SCRIPTDIR=/vagrant

ROOT_DIR=/usr/local
HBASE_INDEXER_DIR=$ROOT_DIR/hbase-indexer
SOLR_DIR=$ROOT_DIR/solr

pushd $ROOT_DIR
echo "Checkpoint: Start Hbase"
pushd hbase/bin
sudo ./start-hbase.sh

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
hbase shell create 'tweets', 'cr', 'enh', 'usr', SPLITS=> ['99999999999999999999', 'KKKKKKKKKKKKKKKKKKKK', 'TTTTTTTTTTTTTTTTTTTT', 'dddddddddddddddddddd', 'nnnnnnnnnnnnnnnnnnnn']
hbase shell create 'tmp-params', 'cf'
hbase shell create 'tmp-results', 'cf'

echo "Checkpoint: set REPLICATION_SCOPE to 1 for 'tweets' table"
hbase shell disable 'tweets'
hbase shell alter 'tweets', {NAME => 'cr', REPLICATION_SCOPE => 1}
hbase shell enable 'tweets'

echo "Checkpoint: add tweets indexer"
pushd $HBASE_INDEXER_DIR
sudo mkdir indexers
sudo cp $SCRIPTDIR/tweets-indexer.xml indexers/tweets.xml

pushd bin
sudo ./hbase-indexer add-indexer -n tweets -c ../indexers/tweets.xml -cp solr.zk=localhost:2181 -cp solr.collection=gettingstarted
popd

popd
