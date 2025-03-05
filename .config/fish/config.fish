eval "$(/opt/homebrew/bin/brew shellenv)"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

fish_add_path "$(brew --prefix)/opt/gnu-sed/libexec/gnubin"
fish_add_path "$(brew --prefix)/opt/make/libexec/gnubin"

set --export FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git/ --exclude .yarn/'
set --export RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"

set --export EDITOR "$(which nvim)"

bass source ~/.nvm/nvm.sh

set --export NVM_DIR "$HOME/.nvm"
function nvm
    bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv 
end

# uv
fish_add_path "/Users/savvy/.local/bin"

if status is-interactive
    atuin init fish | source
    # Commands to run in interactive sessions can go here
end
