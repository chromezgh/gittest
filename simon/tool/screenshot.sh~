#!/bin/bash
# Copyright June 12 2017 SW , Up to date 11/2/2017 
# get the crtc_id where like "id fb pos size"
# Hana: modetest -M mediatek
# 

DEBUG() {
	[ "$_DEBUG" == "on" ]	&& $@ || :
}

# Function: get the crtc_id
# Usage: $0
# modetest -p | grep -A1 crtc | awk 'NR==2{print $2}'
get_crtc_id() {
	modetest -p | grep -A1 crtc | awk 'NR==2{print $2}'
}

Hana_screen() {
	cd /usr/local/autotest/cros/graphics
	python -c 'import drm; s = drm.crtcScreenshot(crtc_id=30); s.save("/tmp/screenshot.png")'
}

# Function: take a screenshot of chrome 
# Usage: $0 
Robo_screen() {
	cd /usr/local/autotest/cros/graphics
	crtc_id1=$(get_crtc_id)
	echo $crtc_id1 > /tmp/crtc
	python -c 'import gbm;f = open("/tmp/crtc"); var = f.read(); var = int(var); s = gbm.crtcScreenshot(crtc_id=var); s.save("/tmp/screenshot.png")'
}

linux_screen() {
	gnome-screenshot -f /tmp/screenshot.png
}

main() {
	if [ "$1" = "Robo" ]; then
		Robo_screen && echo "screenshot successful !" 1>&2
		
	elif [ "$1" = "linux" ]; then
		linux_screen && echo "screenshot successful !" 1>&2	

	else
		echo error
		exit 1
	fi
}

main "$@"  







