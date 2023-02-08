#!/bin/sh

# Get class of a wid
get_class() {
	id=$1
  if [ -z $id ]; then
    echo ""
  else
	  xprop -id $id | sed -n '/WM_CLASS/s/.*, "\(.*\)"/\1/p'
  fi
}

swallow() {
	swallowerid=$1
	swallowingid=$(bspc query -n prev -N)
	grep "^$(get_class $swallowerid)$" ~/.config/bspwm/noswallow && return
	grep "^$(get_class $swallowerid)$" ~/.config/bspwm/terminals && return
	grep "^$(get_class $swallowingid)$" ~/.config/bspwm/terminals || return
	echo $swallowerid $swallowingid >> /tmp/swallowids
	bspc node $swallowingid --flag hidden=on
}

spit() {
	spitterid=$1
	grep "^$spitterid" /tmp/swallowids || return
	spittingid=$(grep "^$spitterid" /tmp/swallowids | head -n1 | awk '{print $2}')
	bspc node $spittingid --flag hidden=off
	bspc node $spittingid -f
	sed -i "/^$spitterid/d" /tmp/swallowids
}

bspc subscribe node_add node_remove | while read -r event
do
	if [ $(echo $event | awk '{ print $1 }') = node_add ]
	then
	swallow $(echo $event | awk '{print $5}')
	else
	spit $(echo $event | awk '{print $4}')
	fi
done
