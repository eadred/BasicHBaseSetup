echo "Install and set mysql server ......................................... "
# Download and Install the Latest Updates for the OS
sudo apt-get update  -y
# Install MySQL Server in a Non-Interactive mode. No password for root
export DEBIAN_FRONTEND="noninteractive"
echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections
apt-get -y install mysql-server
