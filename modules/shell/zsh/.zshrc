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
alias clearq="rm -rf /tmp/q"
alias p="pnpm"
alias isodate='date -u +"%Y-%m-%dT%H:%M:%SZ"'
alias ll="ls -al"
alias ls="exa --group-directories-first --color-scale --icons"
alias mergeclean="find . -type f -name '*.orig' -exec rm -f {} \;"
alias open='xdg-open'
alias pj="openproj"
alias py='python'
alias r="ranger"
alias showq="touch /tmp/q && tail -f /tmp/q"
alias subs="subliminal download -l 'en' -l 'eng' -s"
alias tree="exa --group-directories-first --color-scale --icons --tree"
alias v=nvim
alias wget='wget --content-disposition'
alias xclip="xclip -selection c"
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

# less verbose xev output with only the relevant parts
keys() {
    xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
}

# server command, runs a local server
# tries running a django runserver_plus, falling back to runserver, then falling back to SimpleHttpServer
server() {
    python3 -m http.server ${1:-8000}
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

# load shortcut aliases
[ -f "$HOME/.shortcutrc" ] && source "$HOME/.shortcutrc"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu