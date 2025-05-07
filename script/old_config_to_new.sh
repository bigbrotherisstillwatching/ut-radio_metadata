#!/bin/bash

file="/home/phablet/.config/radio.s710/already_migrated"

if [ ! -f $file ]; then
    sed -i '3,13d' /home/phablet/.config/radio.s710/radio.s710.conf
    touch /home/phablet/.config/radio.s710/already_migrated
fi
