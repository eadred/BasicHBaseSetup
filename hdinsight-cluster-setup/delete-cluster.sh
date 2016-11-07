#!/bin/bash

# Will need to have logged in to azure with 'azure login' before running this

if [ -z "$CLUSTER_NAME" ]; then
  echo "CLUSTER_NAME name not specified"
  exit -1
fi

if [ -z "$CLUSTER_RG" ]; then
  echo "CLUSTER_RG (resource group) not specified"
  exit -1
fi

if [ -z "$STORAGE_ACCT" ]; then
  echo "STORAGE_ACCT (storage account) not specified"
  exit -1
fi

SUB_ID=$(azure account list --json | jq '.[0].id' | sed 's/"\(.*\)"/\1/')
STORAGE_CNT=$(echo $CLUSTER_NAME)-container
STORAGE_ACCT_KEY=$(azure storage account keys list -g $CLUSTER_RG --json $STORAGE_ACCT | jq '.[0].value' | sed 's/"\(.*\)"/\1/')

echo Deleting cluster $CLUSTER_NAME
azure hdinsight cluster delete -q -g $CLUSTER_RG -s $SUB_ID $CLUSTER_NAME

echo Deleting container $STORAGE_CNT
azure storage container delete -q -a $STORAGE_ACCT -k $STORAGE_ACCT_KEY $STORAGE_CNT
