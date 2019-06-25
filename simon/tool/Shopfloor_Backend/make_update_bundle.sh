#!/bin/bash
# Create by Simon 20180705
# [NOTE]: should put this file in setup folder and install pbzip2

usage() {
	echo
	cat <<EOF
******** making update bundle *********************************
$0 <factory_test_image>
Then you can find the factory.tar.bz2 in /tmp/factory.tar.bz2 if successed
NOTE: please install pbzip2 and run this script in setup folder
EOF
	exit 0
}

root="$(dirname "$(realpath "$0")")"
MOUNT_POINT='/mnt/factory_bundle'
UPDATE_BUNDLE="/tmp/factory_$(date +%F_%R).tar.bz2"

if [ -f "$1" ]; then
	FACTORY_IMAGE=$1
else
	usage
fi

INFO(){
	echo "[INFO]: $*" >&2
}

die(){
	umount_point
	echo "[ERROR]: $*" >&2
	exit 1
}

umount_point() {
	INFO Running Command: sudo umount $MOUNT_POINT
	sudo umount $MOUNT_POINT
}

make_update_bundle() {
	mkdir -p $MOUNT_POINT
	if [ -x $root/mount_partition.sh ]; then
		INFO Running Command: $root/mount_partition.sh $FACTORY_IMAGE 1 $MOUNT_POINT
		$root/mount_partition.sh $FACTORY_IMAGE 1 $MOUNT_POINT || die Mount Failed, Please try again!
	fi
	# update bundle is done
	if [ -x $MOUNT_POINT/dev_image ]; then
		INFO Running Command: tar cPf $UPDATE_BUNDLE -I pbzip2 -C $MOUNT_POINT/dev_image/ \
		--exclude factory/MD5SUM factory autotest
		tar cPf $UPDATE_BUNDLE -I pbzip2 -C $MOUNT_POINT/dev_image/ --exclude factory/MD5SUM factory autotest\
		 || die tar cmd error, please check pbzip2 has been installed.
		INFO Done, update bundle directory: $UPDATE_BUNDLE from $FACTORY_IMAGE
	fi
}

# get ma5sum value for next check needed
reset_md5sum() {
	if [ -e $UPDATE_BUNDLE ]; then
		md5sum=$(md5sum $UPDATE_BUNDLE | awk 'NR==1{print $1}')
		sudo chmod 777 $MOUNT_POINT/dev_image/factory/MD5SUM
		echo $md5sum > $MOUNT_POINT/dev_image/factory/MD5SUM && \
		INFO $md5sum  $MOUNT_POINT/dev_image/factory/MD5SUM
	fi
}

make_update_bundle
reset_md5sum
umount_point














:<<EOF
INFO:root:Running command: "mount -o rw,loop,offset=1499463680,sizelimit=1275068416 /tmp/chromiumos_test_image_8182.90_C330.bin /mnt/factory_bundle"
INFO:root:Running command: "tar cf /tmp/factory.tar.bz2 -I pbzip2 -C /mnt/factory_bundle/dev_image --exclude factory/MD5SUM factory autotest"
INFO:root:MD5SUM is 7bf901e59ff8f836675be43829ad4074
INFO:root:Running command: "echo 7bf901e59ff8f836675be43829ad4074 > /mnt/factory_bundle/dev_image/factory/MD5SUM"
INFO:root:Unmounting /mnt/factory_bundle
INFO:root:Retry: Get result in retry_time: 0.
EOF

