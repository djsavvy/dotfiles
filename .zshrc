# uncomment to profile
# zmodload zsh/zprof

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
export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"

# Use gnu sed, make, etc. on macOS
export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="$(brew --prefix)/opt/make/libexec/gnubin:$PATH"


# custom ssh-agent systemd service
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"


# read manpages in neovim
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# fzf/ripgrep quality of life
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git/ --exclude .yarn/'
export RIPGREP_CONFIG_PATH="$HOME/.config/.ripgreprc"

# Set some options for sccache
export SCCACHE_CACHE_SIZE=100G     # some of us use 100GB; you can use less if needed
export RUSTC_WRAPPER=$(which sccache) # to use sccache for rust

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
function ec2connect_mosh() {
  mosh \
    --ssh="ssh -i $1" \
    ubuntu@$(ec2state $2 describe | jq .Reservations\[\].Instances\[\].PublicIpAddress -r) \
    -- \
    tmux
}

# Args: keypair file, instance name
function ec2connect() {
    et \
    ubuntu@$(ec2state $2 describe | jq .Reservations\[\].Instances\[\].PublicIpAddress -r)
}

function podman_start() {
  podman machine init
  podman machine start
}

# enable smooth scrolling in firefox on X.org
export MOZ_USE_XINPUT2=1

# Pure prompt options
zstyle :prompt:pure:git:stash show yes

# User configuration
export MANPATH="/usr/local/man:$MANPATH"

alias ls="eza"
# Note that you can use \ls to ignore the alias

export BAT_THEME="base16"
# alias cat="bat"

export SYSTEMD_EDITOR=$(which nvim)
export EDITOR=$(which nvim)
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
alias gpush="git push"
alias gpus="git push"
alias gpf="git push --force"
function gpuo {
  git push -u origin "$(git branch --show-current)"
}
function gp() {
  local stashed=0
  git diff-index --quiet HEAD -- || {
    git stash && stashed=1
  }
  git pull && git push "$@"
  [[ $stashed -eq 1 ]] && git stash pop
}
alias gc="git checkout"
alias gcb="git checkout -b"
alias gcp="git cherry-pick"
alias gr="git rebase"
alias gri="git rebase -i"
alias gd="git diff"
alias gds="git diff --staged"
alias ga="git add"
alias gap="git add -p"
alias ga.="git add ."
alias gcm="git commit -m"
alias gstat="git status"
alias gca="git commit --amend"
alias gcam="git commit --amend"
alias gs="git stash"
alias gssp="git stash show -p"
alias gsd="git stash drop"
alias gsp="git show -p"
alias gf="git fetch"
alias grh="git reset --hard"

# Cargo aliases
alias carog="cargo"
alias c="cargo" 
alias cb="cargo build"
alias cbr="cargo build --release"
alias cr="cargo run"
alias crr="cargo run --release"

alias cd..="cd .."
alias mke="make"
alias speedtest.net="speedtest"
alias p="ping 1.1.1.1"
alias speedtest="open https://speed.cloudflare.com"

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

alias mixtral="ollama run mixtral"


### GPG Setup

# Sources:
# https://gist.github.com/bmhatfield/cc21ec0a3a2df963bffa3c1f884b676b
# https://gist.github.com/bcomnes/647477a3a143774069755d672cb395ca

# In order for gpg to find gpg-agent, gpg-agent must be running, and there must be an env
# variable pointing GPG to the gpg-agent socket. This little script, which must be sourced
# in your shell's init script (ie, .bash_profile, .zshrc, whatever), will either start
# gpg-agent or set up the GPG_AGENT_INFO variable if it's already running.

# Add the following to your shell init to set up gpg-agent automatically for every shell
if [ -n "$(pgrep gpg-agent)" ]; then
  export GPG_AGENT_INFO="~/.gnupg/S.gpg-agent:$(pgrep gpg-agent):1"
else
  eval $(gpg-agent --daemon)
fi

GPG_TTY=$(tty)
export GPG_TTY

### END GPG Setup



# QT go binding env var setup
export QT_PKG_CONFIG=true

# opam configuration
test -r /home/savvy/.opam/opam-init/init.zsh && . /home/savvy/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

# Rust configuration
source "$HOME/.cargo/env"

# Add fzf to zsh
source "$(brew --prefix fzf)/shell/completion.zsh"
source "$(brew --prefix fzf)/shell/key-bindings.zsh"

### Added by Zinit's installer
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# don't need because compinit comes after sourcing zinit.zsh
# autoload -Uz _zinit
# (( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# Zinit Configuration
# Get some Oh-My-ZSH functionality
zinit snippet OMZ::plugins/shrink-path/shrink-path.plugin.zsh
zinit light-mode for \
  OMZ::lib/functions.zsh \
  OMZ::lib/history.zsh \
  OMZ::lib/key-bindings.zsh

zinit light-mode for \
    OMZ::lib/spectrum.zsh \
    OMZ::lib/termsupport.zsh \
    OMZ::lib/directories.zsh \
    OMZ::lib/completion.zsh

zinit lucid light-mode for \
    zdharma-continuum/fast-syntax-highlighting \
  blockf \
    zsh-users/zsh-completions \

zinit load atuinsh/atuin

export NVM_DIR="$HOME/.nvm"
export NVM_LAZY_LOAD=true
export NVM_COMPLETION=true
zinit light lukechilds/zsh-nvm

# Powerlevel10k prompt
zinit ice depth=1
zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# needed for poetry completions to work
fpath+=~/.zfunc

# Establish completions with zinit
autoload -Uz compinit
compinit
zinit cdreplay -q

export HOMEBREW_GITHUB_API_TOKEN=placeholder

# Created by `pipx` on 2023-05-06 06:58:56
export PATH="$PATH:/Users/savvy/.local/bin"

# Configure zsh history (doing this after the OMZ::lib/history call)
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
setopt INC_APPEND_HISTORY
export HISTTIMEFORMAT="[%F %T] "
setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS


# uncomment to profile
# zprof


# bun completions
[ -s "/Users/savvy/.bun/_bun" ] && source "/Users/savvy/.bun/_bun"

# python pyenv configuration
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"


# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

