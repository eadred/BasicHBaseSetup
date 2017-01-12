SCRIPTDIR=$(dirname $0)

pushd /usr/local/hbase-indexer

echo "Checkpoint: set REPLICATION_SCOPE to 1 for 'tweets' table"
hbase shell disable 'tweets'
hbase shell alter 'tweets', {NAME => 'cr', REPLICATION_SCOPE => 1}
hbase shell enable 'tweets'

echo "Checkpoint: add tweets indexer"
sudo mkdir indexers
sudo cp $SCRIPTDIR/tweets-indexer.xml indexers/tweets.xml

pushd bin
sudo ./hbase-indexer add-indexer -n tweets -c ../indexers/tweets.xml -cp solr.zk=localhost:2181 -cp solr.collection=gettingstarted
popd

popd
