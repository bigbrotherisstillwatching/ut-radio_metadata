#! /bin/bash

file="/home/phablet/.config/radio.s710/radio.s710.defaultsink.txt"
file2="/home/phablet/.config/radio.s710/radio.s710.oldsink.txt"

[ -f $file ] && rm -f $file
[ -f $file2 ] && rm -f $file2
