# Download Pig
sudo wget http://www.mirrorservice.org/sites/ftp.apache.org/pig/pig-0.15.0/pig-0.15.0.tar.gz  

sudo tar -xvf pig-0.15.0.tar.gz 
sudo mv pig-0.15.0 /usr/local/pig
sudo rm pig-0.15.0.tar.gz 

# Update .bashrc with Pig environment variables
sudo echo "export PIG_HOME=/usr/local/pig" >> ~/.bashrc
sudo echo "export PATH=$PATH:/usr/local/pig/bin" >> ~/.bashrc 
sudo echo "export PIG_CLASSPATH=$HADOOP_HOME/conf" >> ~/.bashrc 
source ~/.bashrc
