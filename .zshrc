# If you come from bash you might have to change your $PATH.
export PATH="$HOME/.config/xboxdrv/scripts/:$HOME/go/bin:/usr/lib/ccache/bin/:$HOME/miniconda3/bin:$PATH" 
export PATH=$HOME/bin:/usr/local/bin:$PATH

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

bindkey -v
bindkey '^P' up-history
bindkey '^N' down-history


function zle-line-init zle-keymap-select {
    VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]%  %{$reset_color%}"
    RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/} $EPS1"
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
export KEYTIMEOUT=1


export MANPATH="/usr/local/man:$MANPATH"

alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

alias steam-wine='WINEDEBUG=-all nohup primusrun wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Steam/Steam.exe -no-cef-sandbox &> /dev/null &'
alias witcher3='steam-wine ; cd ~/.wine/drive_c/Program\ Files\ \(x86\)/Steam/steamapps/common/The\ Witcher\ 3/bin/x64/ && WINEDEBUG=fps primusrun witcher3.exe'
