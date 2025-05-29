#!/usr/bin/env bash

set -x 

TESTDIR=/mnt/data/test
RESFILE=sing-node.log
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

mkdir -p $TESTDIR

# BW
for t in $BW_THREADS; do
	#continue
	$ELBENCHO -w -n 0 -t $t -s $BW_SIZE --direct --resfile $RESFILE $TESTDIR
	$ELBENCHO -r -n 0 -t $t -s $BW_SIZE --direct --resfile $RESFILE $TESTDIR
	$ELBENCHO -F -n 0 -t $t $TESTDIR
done

# IOPS
for t in $IOPS_THREADS; do
	#continue
	$ELBENCHO -w -n 0 -t $t -s $IOPS_SIZE --direct $TESTDIR
	$ELBENCHO -w -n 0 -t $t -s $IOPS_SIZE -b 4k --direct --rand --resfile $RESFILE $TESTDIR
	$ELBENCHO -r -n 0 -t $t -s $IOPS_SIZE -b 4k --direct --rand --resfile $RESFILE $TESTDIR
	$ELBENCHO -F -n 0 -t $t $TESTDIR
done

# MD
for t in $MD_THREADS; do
	#continue
	$ELBENCHO -w -r --stat -F -D -d -t $t -n 3 -N 18382 --direct --resfile $RESFILE $TESTDIR
done

