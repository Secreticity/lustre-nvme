#!/bin/bash

directory="/mnt/lustre"
sig_dir="/mnt/share/cykim/signal"
nodename="CN7"
filename="apple"
todaydate=`date "+%m%d"`
todaytime=`date "+%H%M"`

mkdir -p /mnt/share/cykim/result/${todaydate}
echo ${todaydate}"-"${todaytime} > /mnt/share/cykim/result/${todaydate}/Result_${todaytime}_${nodename}.txt

#for bsize in "4G" "8G" "16G" "32G"
for bsize in "4G"
do
	for numjobs in "4"
#	for numjobs in "1" "2" "4" "8" "16"
	do
		for stripecount in "8"
#		for stripecount in "1" "2" "4" "8" "16"
		do
			lfs setstripe -c ${stripecount} /mnt/lustre

			for iter in {1..2}
#			for iter in {1..5}
			do
				rm -rf /mnt/lustre/*
				sleep 2

				/mnt/share/cykim/backup/fio_script.sh ${bsize} ${numjobs} ${nodename} ${filename} ${stripecount} ${todaydate} ${todaytime} ${iter}

				totval=`lfs df -h | awk '$1=="filesystem_summary:" { print $5 }' | grep -oP '\d+'`
				if [ $totval -ge 98 ]; then
					echo " LUSTRE storage 98% FULL --- EMPTY "
					rm -rf ${directory}/${filename}*
					echo "-"
				fi
			done
		done
	done
done

echo "script - DONE"

exit 0