# Dotfiles Setup & Workflow

Adapted from [Steven R. Baker's Stow Guide](https://stevenrbaker.com/tech/managing-dotfiles-with-gnu-stow.html) and [Brandon Invergo's GNU Stow article](http://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html).

---

## 1. Initial Setup (Linux / macOS)

Clone the repo into `~/src/dotfiles` (or `~/dotfiles`):

```bash
git clone <repo-url> ~/src/dotfiles
cd ~/src/dotfiles
```

### Step 1: Stow Universal Dotfiles (Base Layer)
Symlinks all shared dotfiles (`.tmux.conf`, `.gitconfig`, `.starship`, Neovim, etc.) into `$HOME`:

```bash
stow .
```

### Step 2: Apply Machine Profile Overlay (Work vs. Personal)
Apply machine-specific configurations (Pi agent configs, git credentials, work/personal specific tools):

```bash
# On your Work machine:
stow -d profiles -t ~ work

# On your Personal machine:
stow -d profiles -t ~ personal
```

---

## 2. Additional Services & Setup

- **SSH Agent**:
  ```bash
  systemctl --user enable --now ssh-agent
  ```

- **Firefox Theme** (optional, see `firefox/README.md`):
  ```bash
  firefox/install.sh
  ```

- **Windows Setup**:
  See `Microsoft.PowerShell_profile.ps1`, `wt-startup-layout.ps1`, and `Custom Keys.ahk`.

