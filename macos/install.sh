#!/usr/bin/env bash
# Install (or update) the LaunchDaemon that raises the GPU wired-memory limit
# at boot, and apply it immediately.
#
# Why copy instead of stow: launchd refuses LaunchDaemons that are symlinks or
# not owned by root:wheel, so the plist has to be a real root-owned file in
# /Library/LaunchDaemons.
#
# Usage:
#   ./install.sh              # install/update and apply now
#   ./install.sh --uninstall  # remove; limit returns to default on next reboot
set -euo pipefail

[ "$(uname -s)" = Darwin ] || { echo "macOS only" >&2; exit 1; }

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../dotfiles/macos
LABEL="local.iogpu-wired-limit"
SRC="$PKG_DIR/$LABEL.plist"
DST="/Library/LaunchDaemons/$LABEL.plist"

# bootout fails if the job isn't loaded; that's fine.
sudo launchctl bootout "system/$LABEL" 2>/dev/null || true

if [ "${1:-}" = "--uninstall" ]; then
  sudo rm -f "$DST"
  echo "Removed $DST. Reboot (or: sudo sysctl iogpu.wired_limit_mb=0) to restore the default."
  exit 0
fi

plutil -lint "$SRC" >/dev/null
sudo install -m 644 -o root -g wheel "$SRC" "$DST"
# RunAtLoad applies the sysctl as soon as the job is bootstrapped.
sudo launchctl bootstrap system "$DST"

sysctl iogpu.wired_limit_mb
