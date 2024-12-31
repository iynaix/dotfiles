#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Power Menu
#
## Available Styles
#
## style-1   style-2   style-3   style-4   style-5

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"

# Options
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
windows=''
yes=''
no=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Goodbye ${USER}" \
		-sep "|" \
		-mesg "Uptime: $uptime" \
		-theme "$HOME/.cache/wallust/rofi-power-menu.rasi"
}

# Confirmation CMD
confirm_cmd() {
	rofi -dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme "$HOME/.cache/wallust/rofi-power-menu-confirm.rasi"
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -n "$shutdown|$reboot|$windows|$suspend|$logout|$lock" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			# mpc -q pause
			# amixer set Master mute
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			loginctl kill-user "$(whoami)"
		elif [[ $1 == '--windows' ]]; then
			reboot-to-windows
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    "$shutdown")
		run_cmd --shutdown
        ;;
    "$reboot")
		run_cmd --reboot
        ;;
    "$lock")
		# assumes a lock command exists
		lock
        ;;
    "$suspend")
		run_cmd --suspend
        ;;
    "$logout")
		run_cmd --logout
        ;;
    "$windows")
		run_cmd --windows
        ;;
esac
