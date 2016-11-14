#!/bin/bash

sudo mkdir -p /tmp/oozie

pushd /tmp/oozie

echo "Import the helper files ... "
declare -a oozie_helpers=("java-doc-profile.txt" "oozie-db.sql" "oozie-site.json" "provision.sh" )
for file in "${oozie_helpers[@]}"
do
	echo $file
	wget "https://raw.githubusercontent.com/eadred/BasicHBaseSetup/master/oozie-setup/$file" -O $file
done

echo "Installing oozie .................."
sudo chmod +x *.sh
 ./provision.sh

popd


sudo rm -rf /tmp/oozie
