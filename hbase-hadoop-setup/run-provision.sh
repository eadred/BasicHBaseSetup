SCRIPTDIR=$(dirname $0)
if [ -f $SCRIPTDIR/provision.out ]
then
  rm $SCRIPTDIR/provision.out
fi
if [ -f $SCRIPTDIR/provision.err ]
then
  rm $SCRIPTDIR/provision.err
fi

$SCRIPTDIR/provision.sh > >(tee $SCRIPTDIR/provision.out) 2> >(tee $SCRIPTDIR/provision.err >&2)
