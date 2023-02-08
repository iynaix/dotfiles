#! /bin/sh

dunst &
udiskie &

export XCURSOR_PATH=""

# set the pointer
xsetroot -cursor_name left_ptr &

# start clipboard manager
clipmenud &

# start torrents
transmission-daemon &

# setup displays and wallpaper
source ~/bin/wallpaper

# use dbus-launch to init wm with keyring
wm_=bspwm
if [ $wm_ == awesome ]; then
    sxhkd -c "$HOME/.config/awesome/sxhkdrc" &
    exec awesome >> /tmp/awesome_stdout 2>> /tmp/awesome_stderr
else
    exec bspwm
fi
