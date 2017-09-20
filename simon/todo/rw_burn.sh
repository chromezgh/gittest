#!/bin/sh
slot_lists="RW_SECTION_A RW_SECTION_B RW_SHARED RW_LEGACY"
for link in $slot_lists
do
	/usr/sbin/flashrom -i $link -w /usr/local/100.image.bin
	echo " $link slot flashrom completed!"
done
