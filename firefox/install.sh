#!/usr/bin/env bash
# Link Firefox userChrome.css / userContent.css from this repo into the active
# Firefox profile's chrome/ directory using GNU stow.
#
# Why a script instead of stowing into $HOME like everything else:
#   - The profile dir name (e.g. xqncsgyl.dev-edition-default) is random per
#     install, so it can't be a fixed path in the repo.
#   - The Firefox dir lives under a platform-specific, space-containing path.
# So we stow this package straight into the *profile* dir, resolved at runtime.
#
# Usage:
#   ./install.sh                 # auto-detect the dev-edition-default profile
#   ./install.sh <profile-name>  # e.g. default-release, or a full profile path
#   FIREFOX_PROFILE=... ./install.sh
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../dotfiles/firefox
STOW_DIR="$(dirname "$PKG_DIR")"                           # .../dotfiles
PKG="$(basename "$PKG_DIR")"                               # firefox

# Firefox base dir per platform.
case "$(uname -s)" in
  Darwin) FF_BASE="$HOME/Library/Application Support/Firefox" ;;
  Linux)  FF_BASE="$HOME/.mozilla/firefox" ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

INI="$FF_BASE/profiles.ini"
[ -f "$INI" ] || { echo "No profiles.ini at $INI" >&2; exit 1; }

# Resolve the target profile directory.
arg="${1:-${FIREFOX_PROFILE:-}}"
if [ -n "$arg" ] && [ -d "$arg" ]; then
  PROFILE_DIR="$arg"                       # caller passed a full path
else
  want="${arg:-dev-edition-default}"       # match by profile Name= in ini
  rel="$(awk -v want="$want" '
    /^\[/      { name=""; path="" }
    /^Name=/   { name=substr($0,6) }
    /^Path=/   { path=substr($0,6); if (name==want) { print path; exit } }
  ' "$INI")"
  [ -n "$rel" ] || { echo "Profile named \"$want\" not found in $INI" >&2; exit 1; }
  case "$rel" in
    /*) PROFILE_DIR="$rel" ;;              # IsRelative=0 (absolute)
    *)  PROFILE_DIR="$FF_BASE/$rel" ;;     # IsRelative=1 (relative to base)
  esac
fi

echo "Profile: $PROFILE_DIR"
mkdir -p "$PROFILE_DIR/chrome"

# --restow makes it idempotent; --no-folding keeps chrome/ a real dir and links
# the individual files, so anything else Firefox drops in chrome/ is untouched.
stow --dir "$STOW_DIR" --target "$PROFILE_DIR" --no-folding --restow -v "$PKG"

echo
echo "Done. Ensure this pref is set (about:config), then fully restart Firefox:"
echo "  toolkit.legacyUserProfileCustomizations.stylesheets = true"
