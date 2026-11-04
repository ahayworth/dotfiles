# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Day-to-day workflow

**See what chezmoi would change:**
```bash
chezmoi diff
```
This is your go-to "what's going on" command. It shows a unified diff between what chezmoi *would* deploy and what's currently on disk.

**Apply all changes:**
```bash
chezmoi apply
```
Deploys everything — runs templates, decrypts encrypted files, executes run scripts. Add `-v` for verbose output, or `-n` for a dry-run.

**Edit a managed dotfile:**
```bash
chezmoi edit ~/.zshrc
```
Opens the *source* file (`dot_zshrc.tmpl`) in your editor, not the deployed copy. This ensures you're always editing the canonical version.

**Add a new file to chezmoi:**
```bash
chezmoi add ~/.some_new_config
```
Copies the file into the source directory with the correct chezmoi naming convention. Add `--encrypt` for secrets, `--template` if it needs templating.

**See what chezmoi manages:**
```bash
chezmoi managed
```

**Check what a template produces:**
```bash
chezmoi cat ~/.zshrc
```
Shows the rendered output for your current machine's config (mac=true, work=true, etc.).

## Repo layout

`.chezmoiroot` points chezmoi at `home/`, separating dotfile sources from repo infrastructure:

```
bootstrap.sh          # fresh machine setup
Brewfile              # homebrew packages
README.md
home/                 # chezmoi source root
  .chezmoi.toml.tmpl  # init-time config template
  .chezmoiexternal.toml
  .chezmoiignore
  .chezmoiscripts/    # run scripts
  .chezmoitemplates/  # template partials
  dot_zshrc.tmpl      # -> ~/.zshrc
  dot_config/         # -> ~/.config/
  private_dot_ssh/    # -> ~/.ssh/ (0700)
  ...
old/                  # archived dotdrop setup
```

## Agent config

This repo now manages the user-global Claude and Codex workflow entrypoints directly with chezmoi:

- `home/dot_claude/` -> `~/.claude/`
- `home/dot_codex/` -> `~/.codex/`
- `home/.chezmoitemplates/agent/` holds the shared workflow and instruction bodies used by both

Shared defaults cover scope, authorization, verification, and machine-specific
constraints. The Codex and Claude entrypoints add their own instruction-loading
and workflow guidance. Debrief is explicitly invoked as `$debrief` in Codex or
`/debrief` in Claude; both report against the latest agreed scope without
implementing follow-ups.

Inspect the rendered outputs before applying them:

```bash
chezmoi cat ~/.claude/CLAUDE.md
chezmoi cat ~/.codex/AGENTS.md
```

## GnuPG terminal prompts

GnuPG uses `pinentry-curses` on macOS and Linux so passphrase prompts work in a
terminal, including over SSH. The shared Bash/Zsh setup exports `GPG_TTY` when
stdin is a terminal.

On macOS, install `pinentry` with Homebrew (included in `Brewfile`). On Linux,
ensure `/usr/bin/pinentry-curses` is installed: Arch provides it in `pinentry`;
Debian/Ubuntu provide the `pinentry-curses` package.

After installing the package, deploy the configuration and reload the agent:

```bash
chezmoi apply ~/.gnupg/gpg-agent.conf ~/.shell/common
gpgconf --reload gpg-agent
```

Open a new terminal, or run `export GPG_TTY=$(tty)` in the current interactive
shell.

## Editors

Neovim is the primary managed editor:

- `home/dot_config/nvim/init.lua` -> `~/.config/nvim/init.lua`
- Plugins are managed by Neovim's built-in `vim.pack`
- `~/.config/nvim/nvim-pack-lock.json` pins plugin revisions after the first sync
- `EDITOR` and `VISUAL` are set to `nvim`

Legacy Vim remains managed during the transition:

- `home/dot_vimrc` -> `~/.vimrc`
- Existing vim-plug install/update scripts still run
- Homebrew still installs `vim` as a fallback

Neovim does not source or depend on `.vimrc`; the two editor configs are intentionally separate until the legacy Vim cleanup pass.

## How the source directory maps to home

The naming conventions are mechanical:

| Source name | Deployed as |
|---|---|
| `home/dot_zshrc.tmpl` | `~/.zshrc` (template rendered) |
| `home/dot_bash_aliases` | `~/.bash_aliases` (copied as-is) |
| `home/private_dot_ssh/modify_private_config.tmpl` | `~/.ssh/config` (0600, keeps blocks other tools append) |
| `home/encrypted_dot_zshrc.work.asc` | `~/.zshrc.work` (GPG-decrypted) |
| `home/dot_zsh/aliases.tmpl` | `~/.zsh/aliases` |
| `home/dot_config/starship.toml.tmpl` | `~/.config/starship.toml` |

Prefixes: `dot_` becomes `.`, `private_` drops group and other permissions (0700 dirs, 0600 files), `encrypted_` triggers GPG decryption, and `modify_` makes the source a script that reads the live file on stdin and prints the new one. The `.tmpl` suffix means the file is run through Go templates.

## Templates

Templates use Go template syntax with data from `.chezmoi.toml.tmpl`. The variables:

- `.mac` — auto-detected from OS (`true` on Darwin)
- `.laptop` / `.work` — prompted once on `chezmoi init`, then remembered
- `.homebrew_prefix` — always `/opt/homebrew`

Chezmoi builtins like `.chezmoi.os`, `.chezmoi.hostname`, and `.chezmoi.osRelease` are also available in templates.

## Re-initializing (changing answers)

If you get a new machine, or your laptop/work status changes:
```bash
chezmoi init
```
Re-runs the prompts from `.chezmoi.toml.tmpl`. Since it uses `promptBoolOnce`, it only asks questions that haven't been answered yet. To force re-prompting, delete `~/.config/chezmoi/chezmoi.toml` first.

## Run scripts

Scripts in `.chezmoiscripts/` run automatically during `chezmoi apply`:

- `run_once_before_*` — runs once ever (creates directories, installs vim-plug)
- `run_onchange_after_*` — re-runs when a tracked source file changes (the `# hash:` comments contain checksums that trigger this)

Editor-specific hooks are split: the Vim hook updates vim-plug plugins, while the Neovim hook installs missing `vim.pack` plugins and configured Tree-sitter parsers without removing the legacy Vim setup.

To force a `run_once` script to re-run:
```bash
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

## External dependencies

TPM (tmux plugin manager) is declared in `.chezmoiexternal.toml` and cloned automatically on `chezmoi apply` — no git submodules needed.

## Encrypted files

```bash
# View the decrypted content
chezmoi cat ~/.ssh/id_ed25519

# Re-encrypt after changing a secret locally
chezmoi add --encrypt ~/.ssh/id_ed25519
```

GPG will prompt for your passphrase (symmetric encryption).

## Fresh machine bootstrap

```bash
# Option A: clone and run
git clone git@github.com:ahayworth/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
./bootstrap.sh

# Option B: one-liner (installs chezmoi, clones, applies)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ahayworth --source ~/projects/dotfiles
```

## Debugging

```bash
chezmoi doctor          # health check
chezmoi data            # show all template data for this machine
chezmoi source-path ~/.zshrc   # which source file manages a target
chezmoi cat ~/.zshrc    # rendered template output
chezmoi diff            # what would change
chezmoi apply -n -v     # dry-run with verbose output
```
