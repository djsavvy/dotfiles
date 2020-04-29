# If you come from bash you might have to change your $PATH.
export PATH="$HOME/.config/xboxdrv/scripts/:$HOME/go/bin:/usr/lib/ccache/bin/:$HOME/miniconda3/bin:$PATH"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.gem/ruby/2.7.0/bin:$PATH"

# Vagrant on WSL
export PATH="/mnt/c/Program Files/Oracle/VirtualBox:$PATH"
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"

# enable smooth scrolling in firefox on X.org
export MOZ_USE_XINPUT2=1

# Path to your oh-my-zsh installation.
# export ZSH=/home/savvy/.oh-my-zsh

source /usr/share/zsh/share/antigen.zsh

antigen use oh-my-zsh

antigen bundle git
antigen bundle shrink-path
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting  # syntax highlighting needs to be last bundle

antigen theme djsavvy/zsh-theme

antigen apply

# User configuration

# bindkey -v
# bindkey '^P' up-history
# bindkey '^N' down-history
#
#
# function zle-line-init zle-keymap-select {
#     VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]%  %{$reset_color%}"
#     RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/} $EPS1"
#     zle reset-prompt
# }
#
# zle -N zle-line-init
# zle -N zle-keymap-select
# export KEYTIMEOUT=1


export MANPATH="/usr/local/man:$MANPATH"

alias ls="exa"
# Note that you can use \ls to ignore the alias"

alias vim="nvim"
alias vi="nvim"
# Note that you can use \vim to ignore the alias

alias sudo="sudo "
# This allows for alias expansions to work

alias :q="exit"
alias :Q="exit"
alias exi="exit"

# Increase brightness beyond 100
function setbrightnessratio() {
    if [ "$1" != "" ]
    then
        xrandr --output eDP-1 --brightness "$1"
    else
        xrandr --output eDP-1 --brightness 1
    fi
}

# Disable r builtin
disable r


# Aliases to startx with kde, i3, etc.
alias startx_kde="startx /home/savvy/.xinitrc kde"
alias startx_i3="startx /home/savvy/.xinitrc i3"
alias startx_xfce4="startx /home/savvy/.xinitrc xfce4"
alias startx_gnome3="startx /home/savvy/.xinitrc gnome3"

# QT go binding env var setup
export QT_PKG_CONFIG=true

# opam configuration
test -r /home/savvy/.opam/opam-init/init.zsh && . /home/savvy/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

export SYSTEMD_EDITOR="/bin/nvim"
export EDITOR="/bin/nvim"

