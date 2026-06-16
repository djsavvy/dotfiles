# Wrapper: ensure the local Gemma 4 llama-server is up before launching pi,
# and shut it down ~1 min after the last pi exits.
# The real binary is a node script under .../pi-coding-agent/.../bin/pi —
# call it via `command pi`.
function pi --description 'pi coding agent, auto-starting/stopping the local llama-server'
    set -l base http://127.0.0.1:8080
    if not curl -sf -m 2 $base/v1/models >/dev/null 2>&1
        echo "local-coding-agent: llama-server not running, starting it…" >&2
        ~/src/skunkworks-claude-code/local-coding-agent/start_server.sh >&2
        # Wait (up to ~3 min) for weights to load and the server to answer.
        for i in (seq 180)
            if curl -sf -m 2 $base/v1/models >/dev/null 2>&1
                echo "local-coding-agent: server ready." >&2
                break
            end
            sleep 1
        end
        if not curl -sf -m 2 $base/v1/models >/dev/null 2>&1
            echo "local-coding-agent: server didn't come up — check 'tmux attach -t gemma4-server' or logs." >&2
            return 1
        end
    end

    command pi $argv
    set -l rc $status

    # Reaper: 1 min after this pi exits, kill the server unless another pi is
    # still running. The '[a]' in the pattern keeps pgrep from matching this
    # reaper's own command line.
    fish -c 'sleep 60; if not pgrep -f "pi-coding-[a]gent" >/dev/null 2>&1; tmux kill-session -t gemma4-server 2>/dev/null; end' &
    disown

    return $rc
end
