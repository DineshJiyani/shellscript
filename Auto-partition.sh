#!/bin/bash
swap_dev=/dev/xvdf
raid_dev="/dev/xvdg /dev/xvdh"
#Step-1: Creating swap partition
echo "Creating swap partition"
sfdisk -f -uS $swap_dev << EOF
2048,,82,*
EOF
partprobe $swap_dev"1"
echo "Creating swap file-system"
mkswap $swap_dev"1"
swapon $swap_dev"1"
echo "Adding swap details in /etc/fstab "
echo UUID=$(blkid  -o value -s UUID $swap_dev"1") swap swap defaults,nofail 0 2 >> /etc/fstab
#Raid configuration start
echo "checking mdadm package..."
if [ $(rpmquery -a | grep mdadm | wc -l) -eq 0 ]
then
    echo "Installing mdadm package"
    yum install mdadm -y
fi
echo "Creating raid level 0"
yes | mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 $raid_dev  
echo "Creating xfs file-system"
systemctl daemon-reload
mkfs -t xfs /dev/md0
echo "Create backup of the RAID configuration"
echo "DEVICE $raid_dev" > /etc/mdadm.conf
mdadm --detail --scan | sudo tee -a /etc/mdadm.conf
echo "Adding raid 0 file-system details in /etc/fstab "
echo UUID=$(blkid  -o value -s UUID /dev/md0) /opt xfs defaults,nofail,comment=cloudconfig 0 2 >> /etc/fstab
echo "Create a new ramdisk image to properly preload the block device modules for your new RAID configuration"
dracut -H -f /boot/initramfs-$(uname -r).img $(uname -r)
echo "remount all file-systems"
mount -a