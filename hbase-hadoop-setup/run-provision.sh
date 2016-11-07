SCRIPTDIR=$(dirname $0)
if [ -f $SCRIPTDIR/provision.log ]
then
  rm $SCRIPTDIR/provision.log
fi
$SCRIPTDIR/provision.sh | tee $SCRIPTDIR/provision.log
