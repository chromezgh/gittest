#!/bin/bash

repeat_cmd() {
for time in $(seq 1 3)
	do
		#TODO -Simon- how to improve the print info
		echo "[INFO] this is $time time run command: \"$1\" "
		$1
	done
}

build_package() {
	repo sync 
	cros_sdk -- ./build_packages --board hana
}

main() {
	repeat_cmd "build_package"
}

main "$@"
