#!/bin/sh

# Downloads datasets for artifact evaluation

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
AEROOT=$SCRIPTPATH/..

echo "==== Groute Artifact Evaluation Dataset Download ===="

cd $SCRIPTPATH

while [ 1 ]; do
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 --continue ftp://ftp.cs.huji.ac.il/pub/groute/dataset.tar.bz2 && break
    sleep 1s;
done;

tar xvf dataset.tar.bz2 --exclude='*.metadata' && echo "1" >> $AEROOT/dataset.exists

echo "==== Download Complete ===="
