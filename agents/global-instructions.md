# Global agent instructions

Setup links this file into every coding agent's global instructions:
`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.pi/agent/AGENTS.md`.

## Admin rights: elevate with UAC, don't stop

Agent sessions run without admin rights. When a command needs admin, start it elevated
through a UAC prompt and let the user approve it. Don't stop to say "this needs admin."
For example:

```powershell
Start-Process pwsh -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command', "<command> *> `"$env:TEMP\elevated.log`""
```

An elevated window doesn't send its output back to the calling tool. Redirect output to a log
file (or use `Start-Transcript`) and read the log when the window closes.

UAC approval only grants elevation. It doesn't approve the action, so still confirm first
before destructive or outward-facing changes.
