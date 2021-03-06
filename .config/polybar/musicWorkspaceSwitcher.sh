#!/bin/bash

curWorkpace=`i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' | cut -d"\"" -f2`

notify-send $curWorkspace
notify-send $curWorkspace -eq 11:

if [[ "$curWorkpace" == "11:" ]]; 
    then 
        i3-msg workspace back_and_forth
    else 
        i3-msg workspace 11:
fi

