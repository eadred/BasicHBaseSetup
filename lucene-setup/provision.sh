SCRIPTDIR=$(dirname $0)

if [ -z "$STORAGE_ACCT" ]; then
  echo "STORAGE_ACCT (storage account) not specified"
  exit -1
fi

if [ -z "$STORAGE_ACCT_KEY" ]; then
  echo "STORAGE_ACCT_KEY (storage account key) not specified"
  exit -1
fi

if [ -z "$SHARE_NAME" ]; then
  echo "SHARE_NAME (file share name) not specified"
  exit -1
fi

echo Storage account is $STORAGE_ACCT
echo Storage account key is $STORAGE_ACCT_KEY
echo Share name is $SHARE_NAME

sudo apt-get -y install cifs-utils

MOUNT_POINT=/mnt/resultsfs

sudo mkdir $MOUNT_POINT

echo //$STORAGE_ACCT.file.core.windows.net/$SHARE_NAME $MOUNT_POINT cifs vers=3.0,username=$STORAGE_ACCT,password=$STORAGE_ACCT_KEY,dir_mode=0777,file_mode=0777 \
  | sudo tee -a /etc/fstab

sudo mount -a
