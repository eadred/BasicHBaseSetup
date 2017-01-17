
pushd /usr/local

echo "Checkpoint: Start hbase-indexer"
pushd hbase-indexer/bin
sudo ./hbase-indexer server &
popd

popd


echo "Checkpoint: add tweets indexer"
pushd $HBASE_INDEXER_DIR
sudo mkdir indexers
sudo cp $SCRIPTDIR/tweets-indexer.xml indexers/tweets.xml

pushd bin
sudo ./hbase-indexer add-indexer -n tweets -c ../indexers/tweets.xml -cp solr.zk=localhost:2181 -cp solr.collection=gettingstarted

sudo ./hbase-indexer replication-wait
popd

popd
