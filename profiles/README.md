# Dotfiles Machine Profiles

This directory contains machine-specific overlay packages managed with [GNU Stow](https://www.gnu.org/software/stow/).

---

## Profile Architecture (Layered Stow Model)

1. **Base Layer (Universal)** — Files at the root of `dotfiles/`:
   - Common across **all** machines (e.g. `.tmux.conf`, `.starship`, Neovim, common shell tools).
   - Applied via: `stow .`

2. **Overlay Layer (`profiles/work` vs `profiles/personal`)**:
   - Machine-specific differences that mirror `$HOME` but only contain the settings tailored to that environment.
   - Applied on top of the base layer via:
     ```bash
     # On your Work machine:
     stow -d profiles -t ~ work

     # On your Personal machine:
     stow -d profiles -t ~ personal
     ```

---

## Directory Layout

```
profiles/
├── personal/
│   └── .pi/agent/
│       └── settings.json          # Unrestricted: full access to all models/providers
│   # (Add other personal-only files here, e.g. .gitconfig.local, .ssh/config, etc.)
│
└── work/
    └── .pi/agent/
        ├── settings.json          # Enterprise routing (Vertex AI, Azure OpenAI)
        └── extensions/
            └── disable-public-ai.ts
    # (Add other work-only files here, e.g. enterprise registries, work .gitconfig.local, etc.)
```

---

## What is Configured

### Pi Coding Agent

- **`profiles/work`**:
  - `defaultProvider`: `google-vertex` / `azure-openai-responses`
  - Restricts available models to approved enterprise endpoints (`enabledModels`)
  - Contains `disable-public-ai.ts` extension to block public API endpoints
  - Includes `npm:pi-exa` for web search and retrieval

- **`profiles/personal`**:
  - Full access to all models and all providers (Anthropic Claude, OpenAI GPT, Google AI Studio, OpenRouter, DeepSeek, Ollama, Groq, Mistral, Bedrock, etc.)
  - No model filtering (`enabledModels` omitted)
  - No `disable-public-ai.ts` extension
  - Includes `npm:pi-exa` for web search and retrieval

---

## Adding New Profile-Specific Dotfiles

To add other machine-specific dotfiles in the future:
1. Place the file inside `profiles/work/` or `profiles/personal/` mirroring its `$HOME` path (e.g. `profiles/work/.gitconfig.local`).
2. Run `stow -d profiles -t ~ work` (or `personal`) to symlink it.
3. Keep shared/common settings in the repo root.

