# If you come from bash you might have to change your $PATH.
export PATH="$HOME/.config/xboxdrv/scripts/:$HOME/go/bin:/usr/lib/ccache/bin/:$HOME/miniconda3/bin:$PATH" 
export PATH=$HOME/bin:/usr/local/bin:$PATH

# enable smooth scrolling in firefox
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

alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

alias vim="nvim"
alias vi="nvim"
# Note that you can use \vim to ignore the alias

alias sudo="sudo "
# This allows for alias expansions to work

alias :q="exit"
