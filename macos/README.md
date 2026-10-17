# macOS system settings

System-level macOS config that can't live in `$HOME`. Like `firefox/`, this
directory is listed in `../.stow-local-ignore` so `stow .` skips it.

## GPU wired-memory limit (`local.iogpu-wired-limit.plist`)

On Apple Silicon the GPU shares system RAM, but macOS only lets it wire about
75% of it by default (~96 GB on a 128 GB Mac). Large local LLMs need more than
that: `qwen3.8-flash-next:125b-mlx` wires ~98 GB in Ollama, so it fails to load
at the default limit.

The LaunchDaemon runs this at every boot:

    sysctl iogpu.wired_limit_mb=118784   # 116 GB

### Install / update / remove

    ./install.sh              # copies the plist to /Library/LaunchDaemons and applies it now
    ./install.sh --uninstall  # removes it; the default returns on next reboot

Check the current value with `sysctl iogpu.wired_limit_mb` (`0` means the
macOS default). To try a value without persisting it:
`sudo sysctl iogpu.wired_limit_mb=<MB>`.

### Choosing the value

This is a ceiling, not a reservation: memory is only taken while a model is
loaded. The cost is what's left for macOS and apps *while* a big model is
loaded. 116 GB leaves 12 GB.

- With Flash-Next loaded at 112 GB, free memory was ~14% and macOS had already
  swapped ~4.4 GB. 116 GB is about as high as is sensible.
- Don't go to 120 GB+ on a 128 GB machine: with 8 GB left, macOS swaps hard
  and can hang.
- On a Mac with different RAM, scale it: total RAM minus ~12 GB.
