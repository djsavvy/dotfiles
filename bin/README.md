# bin/

Personal utility scripts. Stow symlinks this into `~/bin`, which `config.fish`
already adds to `PATH`, so everything here is runnable by name from anywhere.

| script | what it does |
|--------|--------------|
| `captive-keepalive.sh` | Keeps a UniFi "click to continue" guest-WiFi session alive by replaying the authorize POST whenever it expires. Auto-discovers the portal; `captive-keepalive.sh --help` style usage is documented in the file header. |
