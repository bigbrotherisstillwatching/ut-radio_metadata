#!/bin/bash

file="/home/phablet/.config/radio.s710/already_migrated"
file2="/home/phablet/.config/radio.s710/radio.s710.defaultsink.txt"
file3="/home/phablet/.config/radio.s710/radio.s710.oldsink.txt"

if [ ! -f $file ]; then
    sed -i '3,13d' /home/phablet/.config/radio.s710/radio.s710.conf
    rm -f $file2
    rm -f $file3
    touch $file
fi
