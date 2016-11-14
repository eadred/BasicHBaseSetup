#!/bin/bash

sudo wget http://archive.apache.org/dist/oozie/4.1.0/oozie-4.1.0.tar.gz
sudo tar -xvf oozie-4.1.0.tar.gz
sudo rm oozie-4.1.0.tar.gz

################ Fixing oozie pom.xml ###################

# Set correct url for Codehaus repo
CODEHAUS_URL="https://repository-master.mulesoft.org/nexus/content/groups/public/"
sudo sed -i "s~http://repository.codehaus.org/~$CODEHAUS_URL~" oozie-4.1.0/pom.xml

# Adding a profile to ignore java-doclint warnings regardless of java version used
JAVA_DOC_PROFILE=$(<java-doc-profile.txt)
# Remove new-line symbols
JAVA_DOC_PROFILE=$(sed ':a;N;$!ba;s/\n/ /g' <<< $JAVA_DOC_PROFILE)
sudo sed -i "s~</profiles>~$JAVA_DOC_PROFILE</profiles>~" oozie-4.1.0/pom.xml


########### Install mysql and create oozie DB ###########
echo "Install and set mysql server .......... "
sudo apt-get update
sudo apt-get install mysql-server
sudo mysql -u root < oozie-db.sql


# Build oozie
echo "Building oozie ........."
sudo apt-get install maven
sudo ./oozie-4.1.0/bin/mkdistro.sh -DskipTests -Phadoop-2  -DjavaVersion=1.8 -DjavaTargetVersion=1.8
sudo cp -r oozie-4.1.0/distro/target/oozie-4.1.0-distro/oozie-4.1.0/ /usr/local/oozie


################## Install extra libs #########################
echo "Installing extra libraries ........"
sudo mkdir /usr/local/oozie/libext
sudo curl -O http://archive.cloudera.com/gplextras/misc/ext-2.2.zip
sudo cp ext-2.2.zip /usr/local/oozie/libext/

sudo wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.31.tar.gz
sudo tar -zxf mysql-connector-java-5.1.31.tar.gz 
sudo cp mysql-connector-java-5.1.31/mysql-connector-java-5.1.31-bin.jar /usr/local/oozie/libext/
sudo rm mysql-connector-java-5.1.31.tar.gz


############## Make oozie work with Azure Blobs #################
# Install tool for work with JSON 
sudo apt install jq
sudo sed -i ':a;N;$!ba;s/\n/NEWLINE/g' /usr/local/oozie/conf/oozie-site.xml
PARAMS_NUMBER=$(jq<"oozie-site.json" '.params | length')
for (( i=0; i<$PARAMS_NUMBER; i++ ))
do
     PARAM_NAME=$(jq<"oozie-site.json" --arg index $i '.["params"][$index | tonumber]["name"]')
     PARAM_VALUE=$(jq<"oozie-site.json" --arg index $i '.["params"][$index | tonumber]["value"]')	

     PARAM_NAME=$(sed 's/"//g' <<< $PARAM_NAME)
     PARAM_VALUE=$(sed 's/"//g' <<< $PARAM_VALUE)

     sudo sed -i "s~<name>$PARAM_NAME</name>NEWLINE\s\+<value>[^<>]*</value>~<name>$PARAM_NAME</name><value>$PARAM_VALUE</value>~" /usr/local/oozie/conf/oozie-site.xml

done
sudo sed -i 's/NEWLINE/\n/g'  /usr/local/oozie/conf/oozie-site.xml


# Add hadoop-2.7.3 jars into libext
sudo cp /usr/local/hadoop/share/hadoop/common/*.jar /usr/local/oozie/libext/
sudo cp /usr/local/hadoop/share/hadoop/tools/lib/*.jar /usr/local/oozie/libext/


# Add oozie user and set priviliges for him
sudo adduser oozie
sudo mkdir /usr/local/oozie/logs

sudo chown oozie /usr/local/oozie -R
sudo chmod a+rwx -R /usr/local/oozie


############ Setup Oozie server ###############
su oozie
pushd /usr/local/oozie 
sudo bin/oozie-setup.sh db create -run

sudo apt-get install zip
sudo bin/oozie-setup.sh prepare-war

sudo bin/oozie-setup.sh sharelib create -fs wasb://blob1@iaannastorage.blob.core.windows.net

sudo bin/oozied.sh start

# Update ~/.bashrc  to contain Oozie path and Oozie url
sudo echo "export PATH=$PATH:/usr/local/oozie/bin" >> ~/.bashrc 
sudo echo "export OOZIE_URL=http://$(hostname -f)/oozie/" >> ~/.bashrc
sudo source ~/.bashrc 



