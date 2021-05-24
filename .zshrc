# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
export PATH="$HOME/.config/xboxdrv/scripts/:$HOME/go/bin:/usr/lib/ccache/bin/:$HOME/miniconda3/bin:$PATH"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.gem/ruby/2.7.0/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"


# custom ssh-agent systemd service
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"


# Vagrant on WSL
export PATH="/mnt/c/Program Files/Oracle/VirtualBox:$PATH"
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"

# WSL2 GUI apps with VcXsrv
# set DISPLAY variable to the IP automatically assigned to WSL2
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0

# read manpages in neovim
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# fzf quality of life
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Call Windows programs from terminal
alias sumatra="/mnt/c/Users/savvy/AppData/Local/SumatraPDF/SumatraPDF.exe"
alias explorer="/mnt/c/Windows/SysWOW64/explorer.exe"
alias firefox="/mnt/c/Program\ Files/Firefox\ Developer\ Edition/firefox.exe"
alias edge="/mnt/c/Program\ Files\ \(x86\)/Microsoft/Edge/Application/msedge.exe"
alias shutdown="wsl.exe --shutdown"
alias cmdrun="cmd.exe /c"
alias neovide="neovide-0.7.0.exe --multiGrid --disowned"
function win-notify() {
    powershell.exe -executionpolicy bypass -command New-BurntToastNotification -Text "\"$@\""
}

# Drop caches to free up memory in Windows host (note, this needs to be executed as root)
function drop_caches() {
    local integer amt=$1
    if [[ $# == 0 || ($amt < 1 || $amt > 3) ]];
    then
        amt=1
    fi
    echo "executing: echo $amt > /proc/sys/vm/drop_caches"
    echo $amt > /proc/sys/vm/drop_caches
    echo "executing: echo 1 > /proc/sys/vm/compact_memory"
    echo 1 > /proc/sys/vm/compact_memory
}

# Args: instance name, start/stop/terminate/etc, region (optional)
function ec2state() {
  aws ec2 $2-instances \
    --region ${3:-us-east-1} \
    --instance-ids \
    $( \
      aws ec2 describe-instances \
      --filter Name=tag:Name,Values=$1 \
      --query Reservations\[\*\].Instances\[\*\].InstanceId \
      --output text \
      --region ${3:-us-east-1}\
    )
}

# Args: keypair file, instance name
function ec2connect() {
  mosh \
    --ssh="ssh -i $1" \
    ubuntu@$(ec2state $2 describe | jq .Reservations\[\].Instances\[\].PublicIpAddress -r) \
    -- \
    tmux
}

# enable smooth scrolling in firefox on X.org
export MOZ_USE_XINPUT2=1

# Pure prompt options
zstyle :prompt:pure:git:stash show yes

# User configuration
export MANPATH="/usr/local/man:$MANPATH"

alias ls="exa"
# Note that you can use \ls to ignore the alias

alias cat="bat"

alias vim="nvim"
alias vi="nvim"
# Note that you can use \vim to ignore the alias

# This allows for alias expansions to work
alias sudo="sudo "

alias :e="vim "
alias :E="vim "
alias :q="exit"
alias :Q="exit"
alias exi="exit"
alias g="git"

alias cd..="cd .."

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


# QT go binding env var setup
export QT_PKG_CONFIG=true

# opam configuration
test -r /home/savvy/.opam/opam-init/init.zsh && . /home/savvy/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

export SYSTEMD_EDITOR="/bin/nvim"
export EDITOR="/bin/nvim"

# python pyenv configuration
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export PATH="/home/ubuntu/.pyenv/bin:$PATH"
eval "$(pyenv virtualenv-init -)"
eval "$(pyenv init -)"


### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk

# Zinit Configuration

zinit light zsh-users/zsh-completions
zinit light zdharma/fast-syntax-highlighting

# Get some Oh-My-ZSH functionality
zinit snippet OMZ::plugins/shrink-path/shrink-path.plugin.zsh
zinit for \
    OMZ::lib/history.zsh \
    OMZ::lib/key-bindings.zsh \
    OMZ::lib/spectrum.zsh \
    OMZ::lib/termsupport.zsh \
    OMZ::lib/directories.zsh \
    OMZ::lib/completion.zsh

# Powerlevel10k prompt
zinit ice depth=1
zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Establish completions with zinit
autoload -Uz compinit
compinit
zinit cdreplay -q


source "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source /usr/share/nvm/init-nvm.sh
