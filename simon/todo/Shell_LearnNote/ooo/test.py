# -*- mode: python; coding: utf-8 -*-
#
# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import commands
var=commands.getoutput('cp ~/Desktop/SN.sh ~/')       #输出结果
print var
varstatus=commands.getstatusoutput('echo abc')  
print varstatus[0]

