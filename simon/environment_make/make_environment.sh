#!/bin/sh

# Copyright (c) 25/02/2017 The Bitland SW Simon. All rights reserved.
# make jerry enviroment  

#prepare: 1. .netrc  2.localmanifests  3.comment out the weblot



cd ~/factory_jerry/

#In case of fetch error result from poor network,repo sync many times until grep successfully.
while [ repo sync | grep "Your sources have been sync'd successfully."=null ]
do
	for (( i=1; i<=10; i=i+1))
	do
		repo sync
	done
done

for (( i=1; i<=2; i=i+1 ))
do
	cros_sdk
done

for (( i=1; i<=5; i=i+1 ))
do
	./setup_board --board=veyron_jerry
done

# do it only jerry
cd ../overlays/overlay-veyron/
cp media-libs/mali-drivers-bin/ ../../private-overlays/overlay-veyron-private/media-libs/ -R
cd ../../private-overlays/overlay-veyron-private/media-libs/
ls
rm -rf mali-drivers
ls
cd ../../../
cd private-overlays/
vim overlay-veyron-private/profiles/base/package.use (mali-drivers后加-bin)
vim overlay-veyron-private/virtual/opengles/opengles-3.ebuild (mali-drivers后加-bin)
#======================================================================================

sudo vim /etc/make.conf.user（增加：ACCEPT_LICENSE="*"）
cd ~/trunk/src/scripts/
    ./build_packages --board=veyron_jerry      

