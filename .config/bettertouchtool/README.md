# BetterTouchTool config

BTT stores its real config in a binary SQLite store
(`~/Library/Application Support/BetterTouchTool/btt_data_store.version_*`), which
is noisy to version and breaks on every BTT update (the filename embeds the build
number). So instead of symlinking that, this dir keeps a **readable JSON export**
as a tracked record/backup.

## Files
- `btt-triggers.json` — output of BTT's `get_triggers "{}"` (all triggers).

## Refresh the export
Requires BTT → Settings → Advanced → **Allow external scripting** to be ON.
```fish
osascript -e 'tell application "BetterTouchTool" to get_triggers "{}"' \
  | python3 -c "import sys,json;json.dump(json.load(sys.stdin),open('btt-triggers.json','w'),indent=2,sort_keys=True)"
```
Restore on a new machine = open BTT and import / re-create from this record (BTT
does not auto-import a plain trigger dump — treat this as documentation, not a
drop-in preset).

## Citrix: ⌘⇧S → Win+Shift+S (Windows Snipping Tool)
Goal: inside a Citrix/RDP session, `⌘⇧S` should open the Windows Snipping Tool
instead of taking a macOS screenshot (clipboard transfer into the session is
disabled, so a Mac-side screenshot is useless there).

Two coordinated pieces make this work:

1. **Karabiner** (`../karabiner/karabiner.json`, first complex-modification rule):
   when Citrix (`com.citrix.receiver.icaviewer.mac`) or RDP
   (`com.microsoft.rdc.macos`) is frontmost, remap `left_command+shift+s` →
   `right_command+shift+s`. Citrix's `Config` has `RightCommandAsWindowsLogo=Yes`,
   so **right-⌘ = the Windows logo key** → the session receives `Win+Shift+S`.
   (Left/regular ⌘ maps to Alt in Citrix via `AltCharacter=Command`, which is why
   a plain pass-through would NOT work.)

2. **BTT** screenshot trigger "Capture Screenshot (Configurable)" (`⇧⌘S`,
   UUID `52391D02-3282-4258-BA46-F1BF8E2C8D01`): the
   **"Differentiate between left and right modifier keys"** checkbox is ENABLED,
   so the global screenshot only fires on **left**-⌘. Karabiner's right-⌘ output
   in Citrix therefore passes through BTT untouched and reaches the session.

> ⚠️ The "differentiate left/right" flag is NOT included in `get_triggers` JSON
> (BTT stores it only in the binary store). If you rebuild BTT from scratch, you
> must re-check that box on the `⇧⌘S` screenshot trigger by hand.

Net effect:
- Outside Citrix: `⌘⇧S` → normal BTT screenshot (unchanged).
- Inside Citrix/RDP: `⌘⇧S` → `Win+Shift+S` → Windows Snipping Tool.
