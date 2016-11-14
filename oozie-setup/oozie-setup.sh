#!/bin/bash

sudo mkdir -p /tmp/oozie

cd /tmp/oozie

echo "Import the helper files ... "
declare -a oozie_helpers=("java-doc-profile.txt" "oozie-db.sql" "oozie-site.json" "provision.sh" )
for file in "${oozie_helpers[@]}"
do
	echo $file
	wget "https://raw.githubusercontent.com/eadred/BasicHBaseSetup/master/oozie-setup/$file" -o $file
done

echo "Installing oozie .................."
sudo chmod +x *.sh
 ./provision.sh
