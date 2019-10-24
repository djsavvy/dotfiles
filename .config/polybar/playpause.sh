#!/bin/bash


player_status=$(playerctl status 2> /dev/null)

# Foreground color formatting tags are optional
if [[ $player_status = "Playing" ]]; then
    echo "%{F#2b93c8}"
elif [[ $player_status = "Paused" ]]; then
    echo "%{F#2b93c8}"
else
    echo "%{F#33}"
fi
