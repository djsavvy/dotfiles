#!/bin/bash

LOCKIMAGE=/tmp/i3lock.png
WALLPAPER=/tmp/i3wall.png
icon=~/.config/i3/lock/icons/circlelockclear.png


convert $1 -resize 1920x1080\! $WALLPAPER
feh --bg-scale $WALLPAPER &
convert $WALLPAPER -fill "#222222DA" -colorize 85% -blur "0x5" -pointsize 26 -fill "white" -gravity center "$icon" -gravity center -composite  $LOCKIMAGE
# -annotate +0+160 "Type password to unlock"
