#!/bin/bash
#user input source and destination path
read -p 'Enter the source path: ' src_path
read -p 'Enter the destination IP: ' dst_ip
read -p 'Enter the destination user: ' dst_user
read -p 'Enter the destination path: ' dst_path
#
echo 'Generate source checksum files list'
find $src_path -type f -print0 | xargs -0 md5sum | sort > /tmp/SourceChecksum.txt
#
echo 'Transfer data from source to destination'
rsync -azrP $src_path/ $dst_user@$dst_ip:$dst_path
echo 'Data sync successfully'
#
echo 'Generate destination checksum files list'
ssh $dst_user@$dst_ip "find $dst_path/ -type f -print0 | xargs -0 md5sum | sort > /tmp/DestChecksum.txt"
#
echo 'Copy checksum files from remote to local'
scp $dst_user@$dst_ip:/tmp/DestChecksum.txt /tmp
#
echo 'Compare checksum reports'
awk 'FNR==NR{A[$1]=$NF;next} FNR!=NR && FNR>0{Q=$1;$0=(Q in A)?$0 FS A[$1] "|matched" :$0 "||unmatched" ;print;next} {print}' FS="|" /tmp/DestChecksum.txt /tmp/SourceChecksum.txt > /tmp/checksum_report.txt
#diff -c /tmp/SourceChecksum.txt /tmp/DestChecksum.txt > /tmp/checksum_report.txt
#Run below command if you want to check matches report
#awk -F: 'NR==FNR { n[$0]++ ; next}; $1 in n ' /tmp/SourceChecksum.txt /tmp/DestChecksum.txt > /tmp/match_list.txt 
