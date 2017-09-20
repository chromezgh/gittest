#!/bin/bash

# Copyright (c) 19/04/2017 The Bitland SW. All rights reserved.
:<< \BLOCK
		Function:
	  sync code to dut 
		print diff codes >> sync_log  【】
		factory_restart in dut
BLOCK

Password="test0000"
DUT_IP="101.1.2.9"
local_directory="/home/sw/Desktop/test_latest/"
remote_directory="/usr/local/factory/board/test_latest"

/usr/bin/expect <<-EOF
set time 10 
spawn rsync -avz ${local_directory} root@${DUT_IP}:${remote_directory}
expect "Password: "
send "$Password\n"
expect eof
EOF

ssh root@${DUT_IP} '/usr/local/factory/board/test_latest/update_to_dut.sh'

