#!/bin/bash

var1=$(grep -m 1 "darkMode" /home/phablet/.config/radio.s710/radio.s710.conf)

var2=$(grep -m 1 "favouriteStations" /home/phablet/.config/radio.s710/radio.s710.conf)

var3=$(grep -m 1 "lastStation" /home/phablet/.config/radio.s710/radio.s710.conf)

file="/home/phablet/.config/radio.s710/radio.s710.conf"

sed -i "/darkMode/c $(printf %q "$var1")" /home/phablet/.config/radio.s710/radio.s710.new.conf

sed -i "/favouriteStations/c $(printf %q "$var2")" /home/phablet/.config/radio.s710/radio.s710.new.conf

sed -i "/lastStation/c $(printf %q "$var3")" /home/phablet/.config/radio.s710/radio.s710.new.conf

sleep 2

[ -f $file ] && rm -f $file
