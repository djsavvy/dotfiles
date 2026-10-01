# Git Bash (Git for Windows) config. setup-windows.ps1 writes a ~/.bashrc stub
# that sources this file; it isn't stowed, so Linux/WSL bashrcs are untouched.

# NVM for Windows v2 (shim mode) routes npm through trust-checked proxies, so a
# global install or npm self-update is blocked (NVM4306) or has no shim until
# `nvm reshim`. v1 and v2 link mode use a plain symlink and need none of this.
# Shim mode puts a proxy npm.exe in .nodejs; Node's own npm is npm.cmd. Test it
# with a builtin, since forking readlink is slow under MSYS.
if [[ -f "$LOCALAPPDATA/Author Software/nvm/.nodejs/npm.exe" ]]; then
  npm() {
    command npm "$@"
    local code=$? arg
    if (( code == 0 )); then
      for arg; do
        case $arg in
          -g | --global | --location=global)
            nvm reshim >/dev/null
            break
            ;;
        esac
      done
    fi
    return $code
  }
fi
