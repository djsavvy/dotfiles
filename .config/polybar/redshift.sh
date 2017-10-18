#!/bin/bash

# Specifying the icon(s) in the script
# This allows us to change its appearance conditionally
icon=""

running="false"
pgrep -x redshift &> /dev/null
if [[ "$?" -eq "0" ]]; then
    running="true"
fi

temp=`analyse-gamma | grep temperature: | awk 'NR==1{ print $NF }'`

if [[ "$running" != "true" ]]; then
    echo " %{F#33}$icon${temp}K"       # Greyed out (not running)
elif [[ $temp -ge 5000 ]]; then
    echo " %{F#42A5F5}$icon${temp}K"      
elif [[ $temp -ge 4000 ]]; then
    echo " %{F#EBCB8B}$icon${temp}K"      
else
    echo " %{F#FF9800}$icon${temp}K"       
fi
