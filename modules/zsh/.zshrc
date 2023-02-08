# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'pc'

# Don't start tmux.
zstyle ':z4h:' start-tmux       no

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'no'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
z4h install ohmyzsh/ohmyzsh || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
path=(~/bin $path)

# Export environment variables.
export GPG_TTY=$TTY

# Source additional local files if they exist.
z4h source ~/.env.zsh
z4h source ~/.profile

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
# z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
# z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin
z4h load ohmyzsh/ohmyzsh/plugins/git
z4h load ohmyzsh/ohmyzsh/plugins/git-flow

# Define key bindings.
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace     Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

z4h bindkey undo Ctrl+/ Shift+Tab  # undo the last command line change
z4h bindkey redo Alt+/             # redo the last undone command line change

z4h bindkey z4h-cd-back    Alt+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Alt+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Alt+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Alt+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# Define aliases.
alias :e="nvim"
alias :q="exit"
alias :sp="bspc node -p south; $TERMINAL & disown"
alias :vs="bspc node -p east; $TERMINAL & disown"
alias c="clear"
alias cal="cal -3"
alias calc='ipy -i -c "from math import *"'
alias clearq="rm -rf /tmp/q"
alias du="dust"
alias p="pnpm"
alias gotop="gotop -p"
alias nvim=nvim
alias nvimdiff=nvim -d
alias ipy="ipython3"
alias ifconfig-ext='curl ifconfig.me/all'
alias ipynb="ipy notebook"
alias isodate='date -u +"%Y-%m-%dT%H:%M:%SZ"'
alias ll="ls -al"
alias lns="ln -s"
alias ls="exa --group-directories-first --color-scale --icons"
alias mergeclean="find . -type f -name '*.orig' -exec rm -f {} \;"
alias open='xdg-open'
alias pj="openproj"
alias py='python'
alias r="ranger"
alias showq="touch /tmp/q && tail -f /tmp/q"
alias stopemacs="pkill -SIGUSR2 emacs"
alias subs="subliminal download -l 'en' -l 'eng' -s"
alias todo="rg TODO"
alias tree="exa --group-directories-first --color-scale --icons --tree"
alias v=nvim
alias vi=nvim
alias vim=nvim
alias wget='wget --content-disposition'
alias whereami='echo "$( hostname --fqdn ) ($(hostname -i)):$( pwd )"'
alias xclip="xclip -selection c"
alias y="paru"
alias yay="paru"
alias yn="yarn"
alias yt="yt-dlp"
alias ytaudio="yt --audio-format mp3 --extract-audio"
alias ytsub="yt --write-auto-sub --sub-lang='en,eng' --convert-subs srt"
alias ytplaylist="yt --output '%(playlist_index)d - %(title)s.%(ext)s'"
alias coinfc="openproj coinfc"
alias coinfc-backend="openproj coinfc-backend && workon coinfc-backend"
alias coinfcweb="tmuxp load ~/.tmuxp/coinfcweb.yml"
alias coinfcnative="tmuxp load ~/.tmuxp/coinfcnative.yml"

# cd aliases

alias ..='cd ..'
alias ...='cd ../..'
alias .2='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

#shut zsh up
alias eslint="nocorrect eslint"
alias netlify="nocorrect netlify"

#git stuff
alias gaa="git add --all"
alias gbr="git bisect reset"
alias gcaam="gaa && gcam"
alias gcam="git commit --amend"
alias gdc="git diff --cached"
alias gdi="git diff"
alias gl="git pull"
alias glc='gl origin "$( git rev-parse --abbrev-ref HEAD )"'
alias gpc='gp origin "$( git rev-parse --abbrev-ref HEAD )"'
alias groot='cd $(git rev-parse --show-toplevel)'
alias grh='git reset --hard'
alias gri='git rebase --interactive'
alias gst="git status -s -b && echo && git log | head -n 1"
alias gsub="git submodule update --init --recursive"

# access github page for the repo we are currently in
alias github="open \`git remote -v | grep github.com | grep fetch | head -1 | awk '{print $2}' | sed 's/git:/http:/git'\`"

alias gf="git flow"
alias gff="gf feature"
alias gffco="gff checkout"
alias gfh="gf hotfix"
alias gfr="gf release"
alias gfs="gf support"

# define function aliases
# Suppress output of loud commands you don't want to hear from
# http://www.commandlinefu.com/commands/view/9390/suppress-output-of-loud-commands-you-dont-want-to-hear-from
q() { "$@" > /dev/null 2>&1; }

# system update with autoremove
upd8() {
    yay -Syyu && sudo pacman -Rs $(pacman -Qdtq)
}

# checkout and pull and merge gitflow branch
gffp() {
    gffco $1 && gp
}

# delete a remote branch
grd() {
    gb -D $1
    gp origin --delete $1
}

# delete a remote feature branch
gffrd() {
    gb -D feature/$1
    gp origin --delete feature/$1
}

# find and use manage.py
dj() {
    # coinfc directory no longer matches coinfc-backend
    if [[ -a "coinfc/manage.py" ]] then
       python "coinfc/manage.py" $*
    elif [[ -a "${PWD##*/}/manage.py" ]] then
        python "${PWD##*/}/manage.py" $*
    elif [[ -a "manage.py" ]] then
        python manage.py $*
    else
        return 1 # not found, error out
    fi
}

_dj() {
    declare target_list
    target_list=(`dj -h | sed -nr 's/^\s+(\w+)$/\1/p' | sort -u`)
    _describe -t commands "management commands" target_list
}
compdef _dj dj

# opens the image after it has been generated as well
djgraph() {
    dj graph_models -a -o $* && open $*[-1]
}

# shell or shell_plus
djsp() {
    dj shell_plus --quiet-load $*
    if [[ $? -ne 0 ]]; then
        dj shell $*
    fi
}

# shell_plus in ipython notebook
djspnb() {
    dj shell_plus --notebook
}

# runs the django devserver so that it is accessible on LAN
djls() {
    echo "Django web server can be accessed via http://`ifconfig | perl -nle'/dr:(\S+)/ && print $1' | head -1`:8001/"

    dj runserver_plus 0.0.0.0:8001 $*
    if [[ $? -ne 0 ]]; then
        dj runserver 0.0.0.0:8001 $*
    fi
}

# less verbose xev output with only the relevant parts
keys() {
    xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
}

# server command, runs a local server
# tries running a django runserver_plus, falling back to runserver, then falling back to SimpleHttpServer
server() {
    # is this django?
    dj runserver_plus $*
    if [[ $? -ne 0 ]]; then
        dj runserver $*
        if [[ $? -ne 0 ]]; then
            python3 -m http.server ${1:-8000}
        fi
    fi
}

# searches git history, can never remember this stupid thing
gsearch() {
    # 2nd argument is target path and subsequent arguments are passed thru
    glg -S$1 -- ${2:-.} $*[2,-1]
}

# cd to project dir and open the virtualenv if it exists
openproj () {
    cd ~/projects/
    if [[ $# -eq 1 ]]; then
        cd $1
    fi
}
_openproj() {
    _files -/ -W '/home/iynaix/projects/'
}
compdef _openproj openproj

# cd to repo dir
openrepo () {
    cd ~/repos/
    if [[ $# -eq 1 ]]; then
        cd $1
    fi
}
_openrepo() {
    _files -/ -W '/home/iynaix/repos/'
}
compdef _openrepo openrepo

rezshrc() {
    . ~/.zshrc # reload .zshrc
    # refresh the virtualenv if we are in one
    if [ -d 'env' ]; then
        q source env/bin/activate
    fi
}

# autocompletion for fabric, stolen from:
# https://github.com/kennethreitz/fabric-zsh-completion/blob/master/fab-completion.zsh
_fab_list() {
    declare target_list
    target_list=($(fab --list-format=short --list | sort -u))
    _describe -t commands "fabric commands" target_list
}
compdef _fab_list fab


# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export ANDROID_HOME=~/Android/Sdk
export ANDROID_SDK_ROOT=~/Android/Sdk
export PATH=$HOME/.node_modules/bin:$HOME/.npm/bin:${ANDROID_HOME}/emulator:$PATH
export npm_config_prefix=~/.node_modules

export DJANGO_READ_DOT_ENV_FILE=True

export LF_ICONS="\
tw=:\
st=:\
ow=:\
dt=:\
di=:\
fi=:\
ln=:\
or=:\
ex=:\
*.c=:\
*.cc=:\
*.clj=:\
*.coffee=:\
*.cpp=:\
*.css=:\
*.d=:\
*.dart=:\
*.erl=:\
*.exs=:\
*.fs=:\
*.go=:\
*.h=:\
*.hh=:\
*.hpp=:\
*.hs=:\
*.html=:\
*.java=:\
*.jl=:\
*.js=:\
*.json=:\
*.lua=:\
*.md=:\
*.php=:\
*.pl=:\
*.pro=:\
*.py=:\
*.rb=:\
*.rs=:\
*.scala=:\
*.ts=:\
*.vim=:\
*.cmd=:\
*.ps1=:\
*.sh=:\
*.bash=:\
*.zsh=:\
*.fish=:\
*.tar=:\
*.tgz=:\
*.arc=:\
*.arj=:\
*.taz=:\
*.lha=:\
*.lz4=:\
*.lzh=:\
*.lzma=:\
*.tlz=:\
*.txz=:\
*.tzo=:\
*.t7z=:\
*.zip=:\
*.z=:\
*.dz=:\
*.gz=:\
*.lrz=:\
*.lz=:\
*.lzo=:\
*.xz=:\
*.zst=:\
*.tzst=:\
*.bz2=:\
*.bz=:\
*.tbz=:\
*.tbz2=:\
*.tz=:\
*.deb=:\
*.rpm=:\
*.jar=:\
*.war=:\
*.ear=:\
*.sar=:\
*.rar=:\
*.alz=:\
*.ace=:\
*.zoo=:\
*.cpio=:\
*.7z=:\
*.rz=:\
*.cab=:\
*.wim=:\
*.swm=:\
*.dwm=:\
*.esd=:\
*.jpg=:\
*.jpeg=:\
*.mjpg=:\
*.mjpeg=:\
*.gif=:\
*.bmp=:\
*.pbm=:\
*.pgm=:\
*.ppm=:\
*.tga=:\
*.xbm=:\
*.xpm=:\
*.tif=:\
*.tiff=:\
*.png=:\
*.svg=:\
*.svgz=:\
*.mng=:\
*.pcx=:\
*.mov=:\
*.mpg=:\
*.mpeg=:\
*.m2v=:\
*.mkv=:\
*.webm=:\
*.ogm=:\
*.mp4=:\
*.m4v=:\
*.mp4v=:\
*.vob=:\
*.qt=:\
*.nuv=:\
*.wmv=:\
*.asf=:\
*.rm=:\
*.rmvb=:\
*.flc=:\
*.avi=:\
*.fli=:\
*.flv=:\
*.gl=:\
*.dl=:\
*.xcf=:\
*.xwd=:\
*.yuv=:\
*.cgm=:\
*.emf=:\
*.ogv=:\
*.ogx=:\
*.aac=:\
*.au=:\
*.flac=:\
*.m4a=:\
*.mid=:\
*.midi=:\
*.mka=:\
*.mp3=:\
*.mpc=:\
*.ogg=:\
*.ra=:\
*.wav=:\
*.oga=:\
*.opus=:\
*.spx=:\
*.xspf=:\
*.pdf=:\
*.nix=:\
"

# Change cursor with support for inside/outside tmux
function _set_cursor() {
    if [[ $TMUX = '' ]]; then
      echo -ne $1
    else
      echo -ne "\ePtmux;\e\e$1\e\\"
    fi
}

function _set_block_cursor() { _set_cursor '\e[2 q' }
function _set_beam_cursor() { _set_cursor '\e[6 q' }

function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
      _set_block_cursor
  else
      _set_beam_cursor
  fi
}
zle -N zle-keymap-select

# ensure beam cursor when starting new terminal
precmd_functions+=(_set_beam_cursor)

# load shortcut aliases
[ -f "$HOME/.shortcutrc" ] && source "$HOME/.shortcutrc"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

# pnpm
export PNPM_HOME="/home/iynaix/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end