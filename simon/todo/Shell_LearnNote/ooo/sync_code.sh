#!/bin/sh

# Copyright (c) 06/04/2017 The Bitland SW Simon. All rights reserved.
#function:
# 1.sync code >>>> way 1: use ssh   way   2 : Use complete
# 2.print diff codes > sync_log1  2: rsync
# 3.recall the changes
# 4.help

#$0 (filename)  $1 (first arg) $2 (second arg)
#$@ (all arg)
#$# (number of args)

# help  ./sync_remote --arg1 value1 --arg2 value2
#             $0        $1     $2     $3    $4

num=1  #loop time
to_run="--help"  #will run 

function arg_parse ($@)
{
	echo "first arg is  $1"
	echo "second arg is $2"

}
	
while [ "$i" <= "$@/2" ]
do 
	arg_parse
	
	case $ in
		--sync_remote) 

		;;
		--log_dir)
	  
		;;
		--recall)
	  
		;;
		--help)
	  
		;;
	esac
	
done
