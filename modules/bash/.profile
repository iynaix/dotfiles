# set default variables
export PATH="$PATH:$HOME/bin:$HOME/.npm-global/bin:$HOME/.local/bin"
export EDITOR="nvim"
export TERMINAL="alacritty"

# android studio doesn't display properly in tiling wm
export _JAVA_AWT_WM_NONREPARENTING=1

export DISABLE_AUTO_TITLE="true"

# start bspwm if not already running
[ "$(tty)" = "/dev/tty1" ] && ! pgrep -x bspwm >/dev/null && exec startx

# virtualenvwrapper related settings
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/projects
export VIRTUALENVWRAPPER_SCRIPT=$(which virtualenvwrapper.sh)
source $(which virtualenvwrapper_lazy.sh)
