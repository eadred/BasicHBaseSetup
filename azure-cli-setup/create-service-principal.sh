#!/bin/bash

# Will need to have logged in to azure with 'azure login' and called 'azure config mode arm' before running this

if [ -z "$CLUSTER_RG" ]; then
  echo "CLUSTER_RG (resource group) not specified"
  exit -1
fi

if [ -z "$APP_NAME" ]; then
  echo "APP_NAME not specified"
  exit -1
fi

if [ -z "$APP_PW" ]; then
  echo "APP_PW (application password) not specified"
  exit -1
fi

CREATE_JSON=$(azure ad sp create --json -n $APP_NAME -p $APP_PW)

SP_OBJECT_ID=$(echo $CREATE_JSON | jq '.objectId' | sed 's/"\(.*\)"/\1/')
#APP_ID=$(echo $CREATE_JSON | jq '.appId' | sed 's/"\(.*\)"/\1/')
#APP_OBJECT_ID=$(azure ad app show --json -a $APP_ID | jq '.[0].objectId' | sed 's/"\(.*\)"/\1/')

SUB_ID=$(azure account list --json | jq '.[0].id' | sed 's/"\(.*\)"/\1/')

azure role assignment create \
  --objectId $SP_OBJECT_ID \
  -o Contributor \
  -g $CLUSTER_RG \
  --subscription $SUB_ID

#Also store the tenant and app Ids for use when we are logging on as the application
azure account show --json | jq '.[0].tenantId' | sed 's/"\(.*\)"/\1/' > tenantid
echo $CREATE_JSON | jq '.appId' | sed 's/"\(.*\)"/\1/' > appid

# Can log in with something like this;
#azure login -u $(cat appid) -p $APP_PW --service-principal --tenant $(cat tenantid)
