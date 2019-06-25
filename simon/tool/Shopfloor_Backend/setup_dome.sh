#!/bin/bash
# Create on July 16th 2018 by BLD SW
# Please put this file in setup folder
#

<< EOF
Preparation: linux 16.04.01 server(xenial)
Factory bundle: 

Install Docker(version > 1.10.3): sudo apt-get update && sudo apt-get install docker.io
Download and install factory server:
	1. ./cros_docker.sh pull
	2. ./cros_docker.sh install 
	3. ./cros_docker.sh run

Install Dome: sudo apt-get install ubuntu-desktop chromium-browser
EOF

root="$(dirname "$(realpath "$0")")"

INFO(){
	echo "[INFO]: $*" >&2
}

die(){
	echo "[ERROR]: $*" >&2
	exit 1
}

repeat_cmd() {
for time in $(seq 1 5)
	do
		#TODO -Simon- how to improve the print info
		echo "[INFO] this is $time time run command: \"$*\" "
		$* && return
	done
}


UPDATE_CMD="sudo apt-get update"
INSTALL_DOCKER_CMD="sudo apt-get install docker.io"

# Decide follow 9 packages needed or not
# sudo apt-get ubuntu-desktop chromium-browser
# sudo apt-get update && sudo apt-get install sharutils pigz python-cherrypy3 python-protobuf python-netifaces python-numpy python.json python-pip
# sudo pip install zeep (pip install --upgrade pip)
# Notice[1]

# sudo apt-get update && sudo apt-get install docker.io
# git clone https://chromium.googlesource.com/chromiumos/platform/factory
# cd factroy/setup
# ./cros_docker.sh build
# ./cros_docker.sh run

repeat_cmd $UPDATE_CMD
repeat_cmd $INSTALL_DOCKER_CMD

#Update deployment script and server image
${root}/cros_docker.sh update

INFO Running Command: ${root}/cros_docker.sh pull
${root}/cros_docker.sh pull || die cros_docker.sh pull failed!!!

INFO Running Command: ${root}/cros_docker.sh install
${root}/cros_docker.sh install || die cros_docker.sh install failed!!!

INFO Running Command: ${root}/cros_docker.sh run
${root}/cros_docker.sh run || die cros_docker.sh run failed!!!

#INFO Running Command: ${root}/cros_docker.sh build     1. changing factory server code
#${root}/cros_docker.sh install || die cros_docker.sh build failed!!!
#INFO Running Command: UMPIRE_PORT=1234 ${root}/cros_docker.sh umpire run  2.changing port and re-run umpire
#${root}/cros_docker.sh run || die cros_docker.sh umpire run failed!!!






#[1]
"Warining: 1. don't use the following cmd to install PIP, will ruin your zeep package.
			curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
			python get-pip.py
		  2. don't use `sudo apt-get remove python` it will remove many packages	

解决pip install时locale.Error: unsupported locale setting

				root@ubuntu:~# locale

				locale: Cannot set LC_ALL to default locale: No such file or directory
				LANG=en_US.UTF-8
				LANGUAGE=
				LC_CTYPE="en_US.UTF-8"
				LC_NUMERIC=zh_CN.UTF-8
				LC_TIME=zh_CN.UTF-8
				LC_COLLATE="en_US.UTF-8"
				LC_MONETARY=zh_CN.UTF-8
				LC_MESSAGES="en_US.UTF-8"
				LC_PAPER=zh_CN.UTF-8
				LC_NAME=zh_CN.UTF-8
				LC_ADDRESS=zh_CN.UTF-8
				LC_TELEPHONE=zh_CN.UTF-8
				LC_MEASUREMENT=zh_CN.UTF-8
				LC_IDENTIFICATION=zh_CN.UTF-8
				LC_ALL=

				root@ubuntu:~# export LC_ALL=C
				root@ubuntu:~# locale

				LANG=en_US.UTF-8
				LANGUAGE=
				LC_CTYPE="C"
				LC_NUMERIC="C"
				LC_TIME="C"
				LC_COLLATE="C"
				LC_MONETARY="C"
				LC_MESSAGES="C"
				LC_PAPER="C"
				LC_NAME="C"
				LC_ADDRESS="C"
				LC_TELEPHONE="C"
				LC_MEASUREMENT="C"
				LC_IDENTIFICATION="C"
				LC_ALL=C

				===> Done
"









