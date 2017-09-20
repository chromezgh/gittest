#!/bin/bash

declare default_board_id="pbody";
declare current_board_id=$default_board_id;
declare default_ip_addr="192.168.1.12";
declare current_ip_addr=$default_ip_addr;
declare binary_filetype=1;
declare board_id_info=("glados" "pbody" "oak" "hana" "reef")

# judge whether there is special char in a string
function find_special_char ()
{

	if [ "$1" == "" ]; then
		return -1
	fi

	if [[ "$1" =~ "$2" ]]; then 
		return 0;
	else
		return -1;
	fi
}

# display usage information
function usage_info ()
{
	echo -e "\033[44;37;5m Usage for chrome tools: \033[0m"
}

# clear screen
function clear_screen ()
{
	clear
}

# display board information in 'config' file
function help_info ()
{
	declare -i board_num=0;

	while read board_id
	do
		if [ "$board_id" != "" ]; then
			find_special_char $board_id "["
			if [ $? != 0 ]; then
				((board_num++));
				if [ $board_num -eq 1 ]; then
					echo -e "\033[44;37;5m Find board id as following: \033[0m"	
				fi
				echo -e "      \033[44;37;5m [$board_num] $board_id \033[0m"	
			fi
		fi
	done < config

#	data_len=${#board_id_info[@]};
#	for index in $(seq 0 1 $data_len)
#	do
#	if [ $index -eq 0 ]; then
#		echo -e "\033[44;37;5m Find board id as following: \033[0m"	
#	fi
#		echo -e "      \033[44;37;5m [$index] ${board_id_info[$index]} \033[0m"
#	done
	
	echo -e "\033[44;37;5m Please try again using above board id ... \033[0m"
}

# check whether the input ip is valid or not
function check_ip_addr() {

	ip_addr=$1

	valid_check=$(echo $ip_addr|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
	if echo $ip_addr|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
		if [ ${valid_check:-no} == "yes" ]; then
#			echo -e "\033[44;37;5m IP $ip_addr available \033[0m"
			return 0;
		else
#			echo -e "\033[41;37;5m IP $ip_addr not available \033[0m"
			return -1;
		fi
	else
		echo -e "\033[41;37;5m IP format error! \033[0m"
		return -1;
	fi
}

# check whether in chroot environment or not
function check_in_chroot ()
{
	filepath=~/trunk/src/scripts/
	if [ ! -d "$filepath" ]; then
		echo -e "\033[41;37;5m Please enter the emvironment first! using 'cros_sdk --no-ns-pid' to do it! \033[0m";
		return -1;
	fi
	
	return 0;
}

# check for binary file type and existence
function binary_file_exist() 
{
	filename=$1;

	if [ -f "$filename" ];    then
		if [ $binary_filetype == 1 ]; then
			if [ "${filename##*.}" == "bin" ]; then
				echo -e "\033[44;37;5m Current file is : \033[0m $filename"
				return 1;
			else
				echo -e "\033[41;37;5m Flie type error! \033[0m"
				return 0;
			fi
		else
			if [ "$(file "$filename")" == "$filename: DOS/MBR boot sector" ]; then
				echo -e "\033[44;37;5m Current file is : \033[0m $filename"
				return 1;
			else
				if [ "$(file "$filename")" == "$filename: x86 boot sector" ]; then
					echo -e "\033[44;37;5m Current file is : \033[0m $filename"
					return 1;
				else
					echo -e "\033[41;37;5m Flie type error! \033[0m"
					return 0;
				fi
			fi
		fi 
	fi
	
	return 0;
}

# enum board id
function enum_board_id ()
{
	declare -i flag=0;

	if [ "$1" == "" ]; then
		help_info 
		return -1;	
	fi
	
	while read board_id
	do
		if [ "$board_id" != "" ]; then
			if [ "$board_id" == "$1" ]; then
				echo -e "\033[44;37;5m Current board is "$1", goto next step! \033[0m"
				flag=1
				break;
			fi
		fi
	done < config
	
#	data_len=${#board_id_info[@]};
	
#	for index in $(seq 0 1 $data_len)
#	do
#		if [[ "$1" == ${board_id_info[$index]} ]]; then
#			echo -e "\033[44;37;5m Current board is "$1", goto next step! \033[0m"
#			flag=1
#			break; 
#		fi
#	done

	if [ $flag -ne 1 ]; then
		echo -e "\033[41;37;5m Can't find current board of "$1",please check it and retry again ... \033[0m"
		help_info	
		return -1;
	fi
}

# start servod service
function start_servod_service ()
{
	declare -i index=0;
	declare -i Timeout=10;

#	enum_board_id $current_board_id
#	if [ $? != 0 ]; then
#		echo -e "\033[41;37;5m Start servod service failed! please check your board id and try again! \033[0m"
#		echo -e "\033[44;37;5m If you see this information, you can try following steps! \033[0m"
#		echo -e "\033[44;37;5m -- first : board id isn't currectly, you need check it and input again! \033[0m"
#		echo -e "\033[44;37;5m -- second: the configuration file does not have the board id information,add it to file of"config"! \033[0m"

#		return -1;
#	fi
	sudo pkill -x servod
	sudo servod -b $current_board_id & > temp_log
	grep -l "9999" temp_log

	while [ $index -le $Timeout ];
	do
		sleep 1	
		if [ $? -eq 0 ]; then
			break;
		fi
		((index++));
	done	
	
	rm temp_log
	
	if [ $index -le $Timeout ]; then	
		echo -e "\033[44;37;5m Start servod service successfully, running ... \033[0m"
	fi

	return 0;
}

# faft setup configuration
function faft_setup ()
{
	/usr/bin/test_that --board=$current_board_id $current_ip_addr firmware_FAFTSetup
}

# faft ec test
function faft_ec ()
{
	/usr/bin/test_that --board=$current_board_id $current_ip_addr suite:faft_ec
}

# faft bios test
function faft_bios ()
{
	/usr/bin/test_that --board=$current_board_id $current_ip_addr suite:faft_bios
}

# bvt test
function bvt_test ()
{
	/usr/bin/cros_run_bvt --board $current_board_id --labqual $current_ip_addr
}

# flash pd firmware
function flash_pd ()
{
	filename=~/trunk/firmware/$current_board_id/${current_board_id}"_pd"/ec.bin

	if [ ! -f "$filename" ]; then
		echo -e "\033[41;37;5m The file of $filename doesn't exist! \033[0m";
		exit 1
	fi

	start_servod_service

	case $current_board_id in
		glados | pbody)
			~/trunk/src/platform/ec/util/flash_ec --board ${current_board_id}"_pd" --image $filename
			;;
		oak | hana)
			dut-control spi1_vref:pp3300 usbpd_boot_mode:on ec_boot_mode:on cold_reset:on sleep:0.1 cold_reset:of
			sudo /usr/bin/flash_ec --board=oak_pd --image=$filename
			dut-control spi1_vref:off usbpd_boot_mode:off ec_boot_mode:off cold_reset:on sleep:0.1 cold_reset:off
			;;
		*)      
			~/trunk/src/platform/ec/util/flash_ec --board ${current_board_id}"_pd" --image $filename
			;;
	esac
}

# flash ec firmware
function flash_ec ()
{
	filename=~/trunk/firmware/$current_board_id/ec.bin
	
	if [ ! -f "$filename" ]; then
		echo -e "\033[41;37;5m The file of $filename doesn't exist! \033[0m";
		exit 1
	fi

	start_servod_service
	
	case $current_board_id in
		glados | pbody)
			~/trunk/src/platform/ec/util/flash_ec --board=$current_board_id --image=$filename
			;;
		oak | hana)  
			dut-control spi1_vref:pp3300 usbpd_boot_mode:on ec_boot_mode:on cold_reset:on sleep:0.1 cold_reset:off
			sudo /usr/bin/flash_ec --board=$current_board_id --image=$filename
			dut-control spi1_vref:off  usbpd_boot_mode:off ec_boot_mode:off cold_reset:on sleep:0.1 cold_reset:off
			;;
		*)
			~/trunk/src/platform/ec/util/flash_ec --board=$current_board_id --image=$filename
			;;
	esac
}

# flash bios firmware
function flash_bios ()
{
	default_file="image.serial.bin";
	filename=~/trunk/firmware/$current_board_id/bios.bin

	if [ ! -f "$filename" ]; then
		filename=~/trunk/firmware/$current_board_id/$default_file
		if [ ! -f "$filename" ]; then
			echo -e "\033[41;37;5m The file of $filename doesn't exist! \033[0m";
			exit 1
		fi
	fi
	
	start_servod_service

	case $current_board_id in
		glados | pbody)
			dut-control spi2_buf_en:on spi2_buf_on_flex_en:on spi2_vref:pp3300 cold_reset:on
			sudo flashrom -V -p ft2232_spi:type=servo-v2 -w $filename
			dut-control spi2_buf_en:off spi2_buf_on_flex_en:off spi2_vref:off cold_reset:off
			;;
		oak | hana)
			dut-control spi2_vref:pp1800 spi2_buf_en:on spi2_buf_on_flex_en:on spi_hold:off
		  	sudo /usr/sbin/flashrom -V -p ft2232_spi:type=servo-v2 -w $filename
		  	dut-control spi2_buf_en:off spi2_buf_on_flex_en:off spi2_vref:off
			;;
		*)    
			dut-control spi2_buf_en:on spi2_buf_on_flex_en:on spi2_vref:pp3300 cold_reset:on
			sudo flashrom -V -p ft2232_spi:type=servo-v2 -w $filename
			dut-control spi2_buf_en:off spi2_buf_on_flex_en:off spi2_vref:off cold_reset:off
			;;
	esac
}

#emerge ec
function emerge_ec ()
{
	cros_workon-${current_board_id} start chromeos-ec
	emerge-${current_board_id} chromeos-ec
	cros_workon-${current_board_id} stop  chromeos-ec
}

#emerge bios
function emerge_bios ()
{
	case $current_board_id in
		glados | pbody | reef)   
			cros_workon-${current_board_id} start coreboot chromeos-bootimage
			emerge-${current_board_id} coreboot chromeos-bootimage
			cros_workon-${current_board_id} stop  coreboot chromeos-bootimage
			;;
		*)      
			cros_workon-${current_board_id} start coreboot libpayload depthcharge chromeos-bootimage
			emerge-${current_board_id} coreboot libpayload depthcharge chromeos-bootimage
			cros_workon-${current_board_id} stop coreboot libpayload depthcharge chromeos-bootimage
			;;
	esac
}

# emerge bios and ec
function emerge_all ()
{
	case $current_board_id in
		glados | pbody)   
			cros_workon-${current_board_id} start chromeos-ec coreboot chromeos-bootimage
			emerge-${current_board_id} chromeos-ec coreboot chromeos-bootimage
			cros_workon-${current_board_id} stop  chromeos-ec coreboot chromeos-bootimage
			;;
		*)      
			cros_workon-${current_board_id} start chromeos-ec coreboot libpayload depthcharge chromeos-bootimage
			emerge-${current_board_id} chromeos-ec coreboot libpayload depthcharge chromeos-bootimage
			cros_workon-${current_board_id} stop chromeos-ec coreboot libpayload depthcharge chromeos-bootimage
			;;
	esac

}

# build autotest dir for autotest
function emerge_autotest ()
{
#	cros_workon --board=${current_board_id} autotest-chrome chromeos-base/autotest-chrome
	cros_workon --board=${current_board_id} start autotest-tests
	emerge-${current_board_id} chromeos-base/autotest-tests
	cros_workon --board=${current_board_id} stop  autotest-tests
}

# build mrc package of fsp
function emerge_mrc_pkg ()
{
	emerge-${current_board_id} chromeos-mrc --getbinpkg --binpkg-respect-use=n
}

# build mrc debug version bios to capture mrc log information
function emerge_mrc_debug ()
{
	case $current_board_id in
		glados | pbody)    
			cros_workon-${current_board_id} start     chromeos-mrc coreboot chromeos-bootimage
			USE='fw_debug' emerge-${current_board_id} chromeos-mrc coreboot chromeos-bootimage
			cros_workon-${current_board_id} stop      chromeos-mrc coreboot chromeos-bootimage
			;;
		*)      
			cros_workon-${current_board_id} start     chromeos-mrc coreboot libpayload depthcharge chromeos-bootimage
			USE='fw_debug' emerge-${current_board_id} chromeos-mrc coreboot libpayload depthcharge chromeos-bootimage
			cros_workon-${current_board_id} stop      chromeos-mrc coreboot libpayload depthcharge chromeos-bootimage
			;;
	esac

}

function interface ()
{
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m |                        Usage for this tools                      | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | faft_setup  \${board} \${ip_addr}                                  | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | faft_ec     \${board} \${ip_addr}                                  | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | faft_bios   \${board} \${ip_addr}                                  | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | faft_all    \${board} \${ip_addr}                                  | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | bvt_test    \${board} \${ip_addr}                                  | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | start_servod_service \${board}                                    | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | flash_pd    \${board}                                             | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | flash_ec    \${board}                                             | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | flash_bios  \${board}                                             | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | emerge_ec   \${board}                                             | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | emerge_bios \${board}                                             | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | emerge_all  \${board}                                             | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | emerge_mrc_debug \${board}                                         | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | emerge_mrc_pkg \${board}                                           | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "     \033[44;37;5m | emerge_autotest \${board}                                         | \033[0m";
	echo -e "     \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
}

function enum_cmd ()
{
	# data format: command parameters_num  describtion
	cmd_str=(
		"faft_setup" "2"
		"faft_ec" "2"
		"faft_bios" "2"
		"faft_all" "2"
		"bvt_test" "2"
		"start_servod_service" "1"
		"flash_pd" "1"
		"flash_ec" "1"
		"flash_bios" "1"
		"emerge_ec" "1"
		"emerge_bios" "1"
		"emerge_all" "1"
		"emerge_mrc_debug" "1"
		"emerge_mrc_pkg" "1"
		"emerge_autotest" "1"
	)
	
		cmd_str_dsc=(
		"faft_setup" "2" "This command is to setup board for faft first step, you can find log information at the end of this test."
		"faft_ec" "2" "This command is to start faft of ec test, you can find log information at the end of this test."
		"faft_bios" "2" "This command is to start faft of bios test, you can find log information at the end of this test." 
		"faft_all" "2" "This command is to start faft bios and faft ec test for faft test, you can find log information at the end of this test." 
		"bvt_test" "2" "this command is to start bvt (build validation test) test, you can find log information at the end of this test."
		"start_servod_service" "1" "This command is to start servod board service for configurating servo board. if you can see port 9999 at command log, it's successful."
		"flash_pd" "1" "This command is to start flashing pd firmware for current board."
		"flash_ec" "1" "This command is to start flashing ec firmware for current board."
		"flash_bios" "1" "This command is to start flashing bios firmware for current board."
		"emerge_ec" "1" "This command is to start emerging ec and pd firmware for current board."
		"emerge_bios" "1" "This command is to start emerging bios firmware for current board."
		"emerge_all" "1" "This command is to start emerging pd and ec and bios firmware for current board."
		"emerge_mrc_debug" "1" "This command is to start emerging bios debug version firmware for current board, it can debug mrc code information."
		"emerge_mrc_pkg" "1" "This command is to start emerging intel's mrc package(also call fsp package) for current board. you must build this package when you change some of fsp files before build bios firmware."
		"emerge_autotest" "1" "This command is to start emerging autotest direction for current board. when we repo sync source code, there's new code for our project, we need to build them for future autotest test."
	)
	
	data_len=${#cmd_str[@]};
	
	for index in $(seq 0 2 $data_len)
	do
		if [[ "$1" == ${cmd_str[$index]} ]]; then
			return ${cmd_str[$index+1]}; 
		fi
	done
	
	echo -e "\033[41;37;5m Can't recognize this command! Please check and try again it! \033[0m";
	
	return -1;
}

function main ()
{
	check_in_chroot

	if [ $? -ne 0 ]; then
		return -1;
	fi

	if [ $# -le 1 -o $# -gt 3 ]; then
#		clear
		interface
		return -1;
	fi
	
	# check whether the command is valid or not
	enum_cmd $1
	ret_value=$?
	((para_num=$#-1));
	if [ $ret_value -eq -1 -o $ret_value -ne $para_num ]; then
#		clear
		interface
		return -1;
	fi

	# check whether the input board id is currect or not
	enum_board_id $2
	if [ $? -ne 0 ]; then
#		clear
#		interface
		return -1;
	fi
	current_board_id=$2
	# check whether the input ip address is currect or not
	if [ $# -eq 3 ]; then
		check_ip_addr $3
		if [ $? -ne 0 ]; then
#			clear
			interface
			return -1;
		fi
		current_ip_addr=$3
	fi

	# process command: $1 is command and $* are parameters
	$1 $*
	
	return 0;
}

main $*

