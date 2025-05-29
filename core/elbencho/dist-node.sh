#!/usr/bin/env bash

set -x 

TESTDIR=/mnt/data/test
RESFILE=dist-node.log
ELBENCHO=/usr/local/bin/elbencho
# BW
BW_THREADS="1 32"
#BW_SIZE=128G
BW_SIZE=4G
#BW_SIZE=256M
# IOPS
IOPS_THREADS="1 192"
#IOPS_SIZE=4G
IOPS_SIZE=512M
#IOPS_SIZE=32M
# MD
#MD_THREADS="1 132"
MD_THREADS="1 22"
# Dist
TARGETS="g0016,g0013"
#TARGETS="g00[01-05],g0112"
HOSTS="--hosts $TARGETS"

pdsh -R ssh -w $TARGETS $ELBENCHO --service
mkdir -p $TESTDIR

# BW
for t in $BW_THREADS; do
	#continue
	$ELBENCHO $HOSTS -w -n 0 -t $t -s $BW_SIZE --direct --resfile $RESFILE $TESTDIR
	$ELBENCHO $HOSTS -r -n 0 -t $t -s $BW_SIZE --direct --resfile $RESFILE $TESTDIR
	$ELBENCHO $HOSTS -F -n 0 -t $t $TESTDIR
done

# IOPS
for t in $IOPS_THREADS; do
	#continue
	$ELBENCHO $HOSTS -w -n 0 -t $t -s $IOPS_SIZE --direct $TESTDIR
	$ELBENCHO $HOSTS -w -n 0 -t $t -s $IOPS_SIZE -b 4k --direct --rand --resfile $RESFILE $TESTDIR
	$ELBENCHO $HOSTS -r -n 0 -t $t -s $IOPS_SIZE -b 4k --direct --rand --resfile $RESFILE $TESTDIR
	$ELBENCHO $HOSTS -F -n 0 -t $t $TESTDIR
done

#MD
for t in $MD_THREADS; do
	#continue
	$ELBENCHO $HOSTS -w -r --stat -F -D -d -t $t -n 3 -N 18382 --direct --resfile $RESFILE $TESTDIR
done

$ELBENCHO $HOSTS --quit
