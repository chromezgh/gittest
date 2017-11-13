#!/bin/sh
#cold boot
clear
echo
echo
cat << EOF
*****pelase enter your choise:(1-3)*****
echo
1.Remove SSD verification
2.Run S3 test
3.Run ColdBoot test
4.Exit
EOF
echo
read -p "Now select the top option to:" input
 
case $input in
  1) 
    echo #####Disable ssd root verification#####
    cd /usr/share/vboot/bin/
    sh make_dev_ssd.sh --force --remove_rootfs_verification 
    reboot ;;
  2)
    if [ -e "/usr/local/s3.log" ] 
      then 
        rm "/usr/local/s3.log"
    fi
    read -p "Please Enter S3 Cycle:" s3_cycle
    suspend_stress_test -c $s3_cycle >> /usr/local/s3.log;;
  3)
    if [ -e "/usr/local/cold_boot.log" ] 
      then 
        rm "/usr/local/cold_boot.log"
    fi
    if [ -e "/usr/local/cold_boot.sh" ] 
      then 
        rm "/usr/local/cold_boot.sh"
    fi
    if [ -e "/etc/init/cold_boot.conf" ] 
      then 
        rm "/etc/init/cold_boot.conf"
    fi
    read -p "Please Enter ColdBoot Cycle:" cb_cycle
    cur_dir=`pwd`
    cd $cur_dir
    sudo cp cold_boot.conf /etc/init/
    sudo cp cold_boot.sh /usr/local/
    chmod +x /usr/local/cold_boot.sh
    sh /usr/local/cold_boot.sh -c $cb_cycle;; 
esac