test (uname) = "Darwin" && eval "$(/opt/homebrew/bin/brew shellenv)"

# Source environment variables
if test -f "$HOME/.env"
    set -l env_file_vars (cat "$HOME/.env" | grep -v "^#" | sed -E "s/^([A-Za-z0-9_]+)=(.*)/set --export \1 \2/g")
    for var in $env_file_vars
        eval $var
    end
end

# PATH setup
fish_add_path "$HOME/go/bin" "/usr/lib/ccache/bin/"
fish_add_path "$HOME/bin" "/usr/local/bin"
fish_add_path "$HOME/.gem/ruby/2.7.0/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.cabal/bin" "$HOME/.ghcup/bin"
test (uname) = "Darwin" && fish_add_path "$(brew --prefix)/opt/gnu-sed/libexec/gnubin"
test (uname) = "Darwin" && fish_add_path "$(brew --prefix)/opt/make/libexec/gnubin"
fish_add_path "/Users/savvy/.local/bin"

# bun
set --export BUN_INSTALL "$HOME/.bun"
fish_add_path "$BUN_INSTALL/bin"

# Environment variables
set --export MANPAGER 'nvim +Man!'
set --export MANWIDTH 999
set --export FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git/ --exclude .yarn/'
set --export RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"
set --export SCCACHE_CACHE_SIZE 100G
set --export RUSTC_WRAPPER (command which sccache)
set --export BAT_THEME "base16"
set --export EDITOR (command which nvim)

# NVM setup
switch (uname)
    case Darwin
        bass source ~/.nvm/nvm.sh
        set --export NVM_DIR "$HOME/.nvm"
        function nvm
            bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
        end
    case Linux
        bass source /usr/share/nvm/init-nvm.sh
        bass source ~/.nvm/nvm.sh
        set --export NVM_DIR "$HOME/.nvm"
        function nvm
            bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
        end
end

if status is-interactive
    # Load atuin
    atuin init fish | source

    # Aliases
    alias ls="eza -a"
    alias vim="nvim"
    alias vi="nvim"
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

    # Git functions
    function gpuo
        git push -u origin (git branch --show-current)
    end

    function gp
        set stashed 0
        git diff-index --quiet HEAD -- || begin
            git stash
            set stashed 1
        end

        git pull && git push $argv

        if test $stashed -eq 1
            git stash pop
        end
    end

    # git branch search
    function gcbrs
        git branch \
            --no-color \
            --sort=-committerdate \
            --format='%(refname:short)' | \
        fzf --header 'git checkout' | \
        xargs -r git checkout
    end

    # Aliases for gcbrs
    alias gcbs="gcbrs"
    alias gco="gcbrs"
    alias gcos="gcbrs"

    function gcprs
        gh pr list \
            --search "sort:updated-desc" \
            --json "number,title,headRefName,updatedAt" \
            --template '{{range .}}{{tablerow (printf "#%v" .number) .title .headRefName (timeago .updatedAt)}}{{end}}' | \
        fzf --header 'Checkout PR' | \
        string split -f1 ' ' | \
        string replace '#' '' | \
        xargs -r gh pr checkout
    end

    function gcprs_me
        gh pr list \
            --search "sort:updated-desc" \
            --author "@me" \
            --json "number,title,headRefName,updatedAt" \
            --template '{{range .}}{{tablerow (printf "#%v" .number) .title .headRefName (timeago .updatedAt)}}{{end}}' | \
        fzf --header 'Checkout PR' | \
        string split -f1 ' ' | \
        string replace '#' '' | \
        xargs -r gh pr checkout
    end

    # Aliases for PR functions
    alias ghprs="gcprs"
    alias ghprs_me="gcprs_me"
    alias gcprsme="gcprs_me"
    alias ghprsme="gcprs_me"

    function which
        if test (count $argv) -eq 0
            echo "Usage: which command_name"
            return 1
        end

        for cmd in $argv
            echo "=== running both `which` and `type` on `$cmd` ==="
            echo -n "which: "
            command which $cmd 2>/dev/null || echo "$cmd not found"
            echo
            echo -n "type: "
            type $cmd 2>/dev/null || echo "$cmd not found"
            echo
        end
    end

    # Cargo aliases
    alias carog="cargo"
    alias c="cargo"
    alias cb="cargo build"
    alias cbr="cargo build --release"
    alias cr="cargo run"
    alias crr="cargo run --release"

    # Misc aliases
    alias cd..="cd .."
    alias mke="make"
    alias speedtest.net="speedtest"
    alias p="ping 1.1.1.1"
    alias speedtest="open https://speed.cloudflare.com"

    alias ccusage="npx ccusage@latest"
    alias fun_claude="claude --dangerously-skip-permissions --disallowedTools 'Bash(git push:*)'"
    alias func="fun_claude"

    test (uname) = "Darwin" && alias bu="brew update && brew upgrade"

    alias mixtral="ollama run mixtral"
    alias yd="yarn dev"

    if test -n "$WSL_DISTRO_NAME"
        alias pbcopy='clip.exe'
        alias pbpaste="powershell.exe -command 'Get-Clipboard' | tr -d '\r' | head -n -1"
    end

    # Source fzf integration
    test (uname) = "Darwin" && source "$(brew --prefix fzf)/shell/key-bindings.fish" 2>/dev/null

    if command -v thefuck >/dev/null
        thefuck --alias | source
    end

    if test (hostname) = "SAVVY0422"
        alias upgr="explorer.exe https://explor.faralloncapital.com/upgrade"
    end
end

# Source cargo environment if available
if test -f "$HOME/.cargo/env"
    source "$HOME/.cargo/env"
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/savvy/.cache/lm-studio/bin
