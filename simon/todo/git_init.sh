#!/bin/bash
#
# need a document to start git 

# config your email
git config --global user.name "<name>"
git config --global user.email "<email>"

# create your first repo
mkdir <my_local_repo>
cd <my_local_repo>
git init
touch README.md
git add README.md
git commit -m "first commit"
git remote add origin http://gitee.com/simonhzhou123/easywork.git
