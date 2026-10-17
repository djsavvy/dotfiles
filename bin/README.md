# bin/

Personal utility scripts. Stow symlinks this into `~/bin`, which `config.fish`
already adds to `PATH`, so everything here is runnable by name from anywhere.

| script | what it does |
|--------|--------------|
| `captive-keepalive.sh` | Keeps a UniFi "click to continue" guest-WiFi session alive by replaying the authorize POST whenever it expires. Auto-discovers the portal; `captive-keepalive.sh --help` style usage is documented in the file header. |
| `eas-build-local` | Runs `eas-cli build --local --non-interactive` and, if it fails on the first-time "Distribution Certificate is not validated for non-interactive builds" error, prints the one-time interactive command to bootstrap credentials instead of just failing. Shared by the `scripts/build-ios-local.sh` wrapper in each locally-built Expo app (Anchor, Snowball, Savor). |
| `power-mode-by-adapter.ps1` | Windows/Lenovo only. Sets the AC power mode from the attached USB-C adapter's wattage: Best performance at 60 W or more, Balanced below (power banks, weak chargers). Run by the `PowerModeByAdapter` scheduled task that `setup-windows.ps1` registers; logs to `%LOCALAPPDATA%\power-mode-by-adapter.log`. |
