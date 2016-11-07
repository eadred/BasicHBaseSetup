#!/bin/bash

curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Installed node"

sudo apt-get install -y jq
sudo apt-get install -y pwgen
sudo apt-get install -y gpw

echo "Installed utils"

sudo npm install -g npm

echo "Updated npm"

sudo npm install -g azure-cli

echo "Installed Azure CLI"
