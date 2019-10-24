#!/bin/sh

LOCKIMAGE="/tmp/i3lock.png"
WALLPAPER="/tmp/i3wall.png"
icon="$HOME/.config/i3/lock/icons/computer_locked.png"

# If wallpaper changes on each login, then this can be commented out
# Since it makes for a harsh transition from the old wallpaper to the new one
# Caching optimizes for the case where the wallpaper isn't actually changing -- provides a faster startup
if [ -f $WALLPAPER ]; then
    feh --bg-scale $WALLPAPER &
fi

convert $1 -resize 1920x1080\! $WALLPAPER
feh --bg-scale $WALLPAPER &
convert $WALLPAPER -fill "#222222DA" -colorize 85% -blur "0x5" -pointsize 26 -fill "white" -gravity center "$icon" -gravity center -composite  $LOCKIMAGE
# -annotate +0+160 "Type password to unlock"
