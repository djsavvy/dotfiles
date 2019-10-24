#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

if [ -s ~/.Xmodmap ]; then
  xmodmap ~/.Xmodmap
fi

rfkill block bluetooth
bluetooth off


echo " "
echo " "
echo "Received argument: $1"
echo " "


# Include argument functionality for startx

# Default case
if [ "$#" = "0" ]; then
    session="i3"
else 
    session="$1"
fi

case $session in
    "i3") 
        echo "Starting with i3..."
        exec i3
        ;;
    "gnome"|"gnome3")
        echo "Starting with gnome..."
        # export GDK_BACKEND=x11
        exec gnome-session
        ;;
    "kde")
        echo "Starting with kde..."
        exec startkde
        ;;
    "xfce4"|"xfce")
        echo "Starting with xfce4..."
        exec startxfce4
        ;;
    *)
        echo "Invalid Argument"
        exit 1
        ;;
esac

