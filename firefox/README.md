# Firefox userChrome

Custom Firefox chrome CSS (`userChrome.css`, `userContent.css`).

Setup: macOS, Firefox Developer Edition, tabs hidden + [Sidebery] in the
sidebar. `userChrome.css` is the macOS-specific
[`hide_tabs_toolbar_osx.css`] + [`window_control_placeholder_support.css`] pair
from MrOtherGuy's firefox-csshacks.

## Why this isn't stowed into `$HOME`

Unlike the rest of the repo, this package is **not** symlinked into `$HOME`. The
files belong in a Firefox *profile* directory:

    ~/Library/Application Support/Firefox/Profiles/<random>.dev-edition-default/chrome/

The `<random>` profile name differs per install, and the base path is
platform-specific, so it can't be a fixed path in the repo. Instead,
`install.sh` resolves the profile at runtime (from `profiles.ini`) and stows
this package straight into the profile's `chrome/` dir. `firefox/` is therefore
listed in `../.stow-local-ignore` so the main `stow dotfiles` skips it.

## Install / re-link

    ./install.sh                 # auto-detects the dev-edition-default profile
    ./install.sh default-release # or another profile by name
    ./install.sh /full/path/to/profile

It's idempotent (`stow --restow`). After linking, set in `about:config`:

    toolkit.legacyUserProfileCustomizations.stylesheets = true

then fully quit and reopen Firefox (a reload won't pick up changes).

## ⚠️ macOS note: do not "upgrade" to `hide_tabs_toolbar_v2.css`

Upstream marked the two source files "deprecated" in favor of
`hide_tabs_toolbar_v2.css`. **That v2 file does not work on macOS** — it assumes
the window controls reflow into `#nav-bar` (Windows/Linux behavior), but on
macOS the traffic-light buttons stay inside `#TabsToolbar`, so v2 collapses them
out of existence. The macOS-specific files here are the correct approach.

The one real maintenance gotcha: Firefox 136 renamed the window root attribute
`tabsintitlebar` → `customtitlebar`. If a future Firefox update breaks the
window-control spacing again, check whether that attribute was renamed again.

[Sidebery]: https://github.com/mbnuqw/sidebery
[`hide_tabs_toolbar_osx.css`]: https://github.com/MrOtherGuy/firefox-csshacks/blob/master/chrome/deprecated/hide_tabs_toolbar_osx.css
[`window_control_placeholder_support.css`]: https://github.com/MrOtherGuy/firefox-csshacks/blob/master/chrome/deprecated/window_control_placeholder_support.css
