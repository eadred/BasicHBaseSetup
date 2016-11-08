#!/bin/bash

if [ -z "$APP_PW" ]; then
  echo "APP_PW (application password) not specified"
  exit -1
fi

azure login -u $(cat appid) -p $APP_PW --service-principal --tenant $(cat tenantid)

azure config mode arm
