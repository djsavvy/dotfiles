function claude --description 'claude, auto-accepting the workspace trust dialog for the current directory'
    set -l cfg ~/.claude.json
    if test -f $cfg
        set -l cwd (pwd)
        set -l tmp "$cfg.tmp.$fish_pid"
        if jq --arg cwd "$cwd" '.projects[$cwd] = ((.projects[$cwd] // {}) + {hasTrustDialogAccepted: true})' $cfg > $tmp 2>/dev/null
            mv $tmp $cfg
        else
            rm -f $tmp
        end
    end
    command claude $argv
end
