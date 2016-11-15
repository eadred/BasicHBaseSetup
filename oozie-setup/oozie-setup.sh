#!/bin/bash

sudo mkdir -p /tmp/oozie

LOG_DIRECTORY=/home/oozie/logs
LOG_FILE=$LOG_DIRECTORY/oozie-setup.log
if [ ! -d "$LOG_DIRECTORY" ]; then
	sudo mkdir -p $LOG_DIRECTORY	
fi

if [ -e "$LOG_FILE" ]; then
	sudo rm $LOG_FILE
fi

pushd /tmp/oozie

sudo touch $LOG_FILE

echo "Import the helper files ... " > $LOG_FILE
declare -a oozie_helpers=("java-doc-profile.txt" "oozie-db.sql" "oozie-site.json" "provision.sh" )
for file in "${oozie_helpers[@]}"
do
	echo $file
	wget "https://raw.githubusercontent.com/eadred/BasicHBaseSetup/master/oozie-setup/$file" -O $file > $LOG_FILE
done

echo "Installing oozie .................." > $LOG_FILE
sudo chmod +x *.sh
 ./provision.sh > $LOG_FILE

popd


sudo rm -rf /tmp/oozie
