#/!/bin/sh
FLAGS=$(xset -q | awk 'NR==2' | awk '{ print $10 }')
if [ "$FLAGS" = 00000000 ] || [ "$FLAGS" = 00000002 ]; then
    xset led on
else
    xset led off
fi

