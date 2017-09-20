#!/bin/sh

# Copyright (c) 28/02/2017 The Bitland SW Simon. All rights reserved.
# upper the serial_number ,if serial_number =NULL then  [unfinished]
# command: str="$(echo $str | tr 'a-z' 'A-Z'

vpd -s serial_number=`vpd -g serial_number | tr 'a-z' 'A-Z'`

