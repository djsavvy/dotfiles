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


# read manpages in neovim
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# fzf/ripgrep quality of life
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git/'
export RIPGREP_CONFIG_PATH="$HOME/.config/.ripgreprc"

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

export BAT_THEME="base16"
alias cat="bat"

export SYSTEMD_EDITOR="/bin/nvim"
export EDITOR="/bin/nvim"
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

# Git aliases
alias g="git"
alias gi="git"
alias gpul="git pull"
alias gpull="git pull"
alias gc="git checkout"
alias gcp="git cherry-pick"
alias gr="git rebase"
alias gri="git rebase -i"
alias gd="git diff"
alias gds="git diff --staged"
alias ga="git add"
alias gap="git add -p"
alias gcm="git commit -m"
alias gstat="git status"
alias gpush="git push"

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

# python pyenv configuration
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Rust configuration
source "$HOME/.cargo/env"

# nvm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


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

### End of Zinit's installer chunk

# Zinit Configuration

zinit wait lucid light-mode for \
    zdharma/fast-syntax-highlighting \
  blockf \
    zsh-users/zsh-completions \

# Get some Oh-My-ZSH functionality
zinit snippet OMZ::plugins/shrink-path/shrink-path.plugin.zsh
zinit light-mode for \
  OMZ::lib/history.zsh \
  OMZ::lib/key-bindings.zsh

zinit wait lucid light-mode for \
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
