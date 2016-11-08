#!/bin/bash

# Will need to have logged in to azure with 'azure login' and called 'azure config mode arm' before running this

if [ -z "$CLUSTER_RG" ]; then
  echo "CLUSTER_RG (resource group) not specified"
  exit -1
fi

if [ -z "$CLUSTER_LOC" ]; then
	#Use 'azure location list' to get the possibilities
  echo "CLUSTER_LOC (location) not specified"
  exit -1
fi

if [ -z "$CLUSTER_VNET" ]; then
  echo "CLUSTER_VNET (cluster virtual network name) not specified"
  exit -1
fi

if [ -z "$STORAGE_ACCT" ]; then
  echo "STORAGE_ACCT (storage account) not specified"
  exit -1
fi

if [ -z "$RESULTS_CNT" ]; then
  echo "RESULTS_CNT (results container) not specified"
  exit -1
fi

# Use 'azure vm sizes --location=$LOC' to get the list of possibilities
# These are the minimum sizes that can be used with the cluster
WORKER_NODE_SIZE=Standard_A3
HEAD_NODE_SIZE=Standard_A3
ZK_NODE_SIZE=Standard_A2
WORKER_NODE_COUNT=1

SUB_ID=$(azure account list --json | jq '.[0].id' | sed 's/"\(.*\)"/\1/')
STORAGE_ACCT_KEY=$(azure storage account keys list -g $CLUSTER_RG --json $STORAGE_ACCT | jq '.[0].value' | sed 's/"\(.*\)"/\1/')
export CLUSTER_NAME=ia-cluster-$(head /dev/urandom | tr -dc a-z0-9 | head -c 10 ; echo '')
STORAGE_CNT=$(echo $CLUSTER_NAME)-container
VNET_CONFIG=$(azure network vnet show --json -g $CLUSTER_RG -n $CLUSTER_VNET)
VNET_ID=$(echo $VNET_CONFIG | jq '.id' | sed 's/"\(.*\)"/\1/')
SUBNET_ID=$(echo $VNET_CONFIG | jq '.subnets[0].id' | sed 's/"\(.*\)"/\1/')

CLUST_UN=$(gpw 1 8)
CLUSTER_PW=$(pwgen -ycn1 10)
CLUST_SSH_UN=$(gpw 1 8)
CLUSTER_SSH_PW=$(pwgen -ycn1 10)

echo $CLUST_UN > ./cluster-un
echo $CLUSTER_PW > ./cluster-pw
echo $CLUST_SSH_UN > ./cluster-ssh-un
echo $CLUSTER_SSH_PW > ./cluster-ssh-pw
echo $CLUSTER_NAME > ./cluster-name

echo Creating cluster config
RES_ROOT_PATH=wasb://$RESULTS_CNT@$STORAGE_ACCT.blob.core.windows.net
CLUSTER_CONFIG="./clusterconfig"
azure hdinsight config create -v --configFilePath $CLUSTER_CONFIG --overwrite true # For some reaosn not having the -v option means this command hangs
azure hdinsight config add-config-values \
  --configFilePath $CLUSTER_CONFIG \
  -s $SUB_ID \
  --core-site fs.azure.page.blob.dir=$RES_ROOT_PATH/hbase/WALs,$RES_ROOT_PATH/hbase/oldWALs,/mapreducestaging,$RES_ROOT_PATH/hbase/MasterProcWALs,/atshistory,/tezstaging,/ams/hbase \
  --hbase-site hbase.rootdir=$RES_ROOT_PATH/hbase

echo Creating container $STORAGE_CNT
azure storage container create \
	-a $STORAGE_ACCT \
	-k $STORAGE_ACCT_KEY \
	$STORAGE_CNT

echo Creating cluster $CLUSTER_NAME
azure hdinsight cluster create \
	-g $CLUSTER_RG \
	-l $CLUSTER_LOC \
	-y Linux \
	--version 3.4 \
	--clusterType HBase \
	--clusterTier Standard \
	--defaultStorageAccountName $STORAGE_ACCT.blob.core.windows.net \
	--defaultStorageAccountKey $STORAGE_ACCT_KEY \
	--defaultStorageContainer $STORAGE_CNT \
	--virtualNetworkId $VNET_ID \
	--subnetName $SUBNET_ID \
	--headNodeSize $HEAD_NODE_SIZE \
	--workerNodeCount $WORKER_NODE_COUNT \
	--workerNodeSize $WORKER_NODE_SIZE \
	--zookeeperNodeSize $ZK_NODE_SIZE \
	--userName $CLUST_UN \
	--password $CLUSTER_PW \
	--sshUserName $CLUST_SSH_UN \
	--sshPassword $CLUSTER_SSH_PW \
  --configurationPath $CLUSTER_CONFIG \
	-s $SUB_ID \
	$CLUSTER_NAME
