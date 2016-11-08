#!/bin/bash

curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Installed node"

sudo apt-get install -y jq
sudo apt-get install -y pwgen
sudo apt-get install -y gpw
sudo apt-get install -y sshpass

echo "Installed utils"

sudo npm install -g npm

echo "Updated npm"

sudo npm install -g azure-cli

echo "Installed Azure CLI"

# Disable telemetry so we don't get prompted the first time we try and do anything
# with the Azure CLI
azure telemetry -d

echo "Done"
