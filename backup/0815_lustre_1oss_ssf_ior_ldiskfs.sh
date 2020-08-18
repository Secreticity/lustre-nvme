#!/bin/bash

directory="/mnt/lustre"
sig_dir="/mnt/share/cykim/signal"
nodename="CN7"
filename="apple"
todaydate=`date "+%m%d"`
todaytime=`date "+%H%M"`
SECONDS=0
experiment="1"

mkdir -p /mnt/share/cykim/result/${todaydate}
echo ${todaydate}"-"${todaytime} > /mnt/share/cykim/result/${todaydate}/Result_${todaytime}_${nodename}.txt


for xfersize in "1M" "2M" "4M" "8M" "16M" "32M" "64M" "128M" "256M"
do
	for blocksize in $xfersize
	do
		for bsize in $xfersize
		do
			for numjobs in "1" "2" "4" "8" "16" "32" "64"
			do
				for stripecount in "1" "2" "4" "8" "16" "32" "64"
				do
					lfs setstripe -C ${stripecount} /mnt/lustre
					lfs setstripe -S ${xfersize} /mnt/lustre

					for iter in {1..1}
					do
						rm -rf /mnt/lustre/*
						sleep 5

						echo 3 > /proc/sys/vm/drop_caches
						if [[ $experiment =~ "1" ]]; then
							ssh pm1 'echo 3 > /proc/sys/vm/drop_caches'
							sleep 1
						fi
						if [[ $experiment =~ "2" ]]; then
							ssh pm2 'echo 3 > /proc/sys/vm/drop_caches'
							sleep 1
						fi
						if [[ $experiment =~ "3" ]]; then
							ssh pm3 'echo 3 > /proc/sys/vm/drop_caches'
							sleep 1
						fi
						if [[ $experiment =~ "4" ]]; then
							ssh pm4 'echo 3 > /proc/sys/vm/drop_caches'
							sleep 1
						fi

						#iostat initiate
						if [[ $experiment =~ "1" ]]; then
							ssh pm1 'iostat -d nvme0n1 nvme1n1 nvme2n1 nvme3n1 -c 1 | grep nvme > /mnt/share/cykim/result/output1' &
						fi
						if [[ $experiment =~ "2" ]]; then
							ssh pm2 'iostat -d nvme0n1 nvme1n1 nvme2n1 nvme3n1 -c 1 | grep nvme > /mnt/share/cykim/result/output2' &
						fi
						if [[ $experiment =~ "3" ]]; then
							ssh pm3 'iostat -d nvme0n1 nvme1n1 nvme2n1 nvme3n1 -c 1 | grep nvme > /mnt/share/cykim/result/output3' &
						fi
						if [[ $experiment =~ "4" ]]; then
							ssh pm4 'iostat -d nvme1n1 nvme2n1 nvme3n1 nvme4n1 -c 1 | grep nvme > /mnt/share/cykim/result/output4' &
						fi

						/mnt/share/cykim/backup/ior_script.sh ${bsize} ${numjobs} ${nodename} ${filename} ${stripecount} ${todaydate} ${todaytime} ${iter} ${directory}

						/mnt/share/cykim/backup/result_iostat_save.sh ${todaydate} ${todaytime} ${nodename} ${experiment}

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
	done
done

duration=$SECONDS
echo "$(($duration / 3600)) hours, $(($duration % 3600 / 60)) minutes, and $(($duration % 60)) seconds elapsed. SCRIPT DONE"
exit 0
