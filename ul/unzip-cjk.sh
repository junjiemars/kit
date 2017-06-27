#!/bin/bash
#------------------------------------------------
# target: unzip cjk codepage zip file
# author: junjiemars@gmail.com
#------------------------------------------------

CP="${CP:-cp936}"

unzip -O $CP $@
