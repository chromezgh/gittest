#!/bin/sh
# Author: Factory team 11/2/2017
# Usage: 
# Function: 1.check USB is ready  2.make usb-stick automaticly, 
# Print installtion info and input Y/N by user to confirm 
# Addition: achieve make usbimg automaticly 
# pv -preb ./chromiumos_test_image_10078.bin  | sudo dd of=/dev/sdb bs=8M iflag=fullblock oflag=dsync
#

info() {
	echo -e "\033[32;49;1m$*\033[39;49;0m" 1>&2
}

warn() {
	echo -e "\033[31;49;1m$*\033[39;49;0m" 1>&2
	exit 1
}

# Function: 
# Usage: $0 <input_img> <output_dev>
make_Ustick() {
	if [ "$2" = "/dev/sda" ]; then
		warn Are you sure this output is right?
		return
	fi
	echo -e "\033[32;49;1m"
	set -x
	pv -preb $1 | sudo dd of=$2 bs=8M iflag=fullblock oflag=dsync || warn Failed
	echo -e "\033[39;49;0m"
	sleep 10; sync
	sudo eject -s $2  # eject U-stick
	set +x
	info Done 
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	info "Usage: $0 <input> <output>"
	exit 1
fi
echo "Usage: $0 <input> <output>" 1>&2
make_Ustick "$@"









