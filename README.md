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
mise.toml             # mise task definitions
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

## How the source directory maps to home

The naming conventions are mechanical:

| Source name | Deployed as |
|---|---|
| `home/dot_zshrc.tmpl` | `~/.zshrc` (template rendered) |
| `home/dot_bash_aliases` | `~/.bash_aliases` (copied as-is) |
| `home/private_dot_ssh/config.tmpl` | `~/.ssh/config` (0700 dir, template) |
| `home/encrypted_dot_zshrc.work.asc` | `~/.zshrc.work` (GPG-decrypted) |
| `home/dot_zsh/aliases.tmpl` | `~/.zsh/aliases` |
| `home/dot_config/starship.toml.tmpl` | `~/.config/starship.toml` |

Prefixes: `dot_` becomes `.`, `private_` sets 0700 permissions, `encrypted_` triggers GPG decryption. The `.tmpl` suffix means the file is run through Go templates.

## Templates

Templates use Go template syntax with data from `.chezmoi.toml.tmpl`. The variables:

- `.mac` — auto-detected from OS (`true` on Darwin)
- `.laptop` / `.work` — prompted once on `chezmoi init`, then remembered
- `.codespaces` — auto-detected from `$CODESPACES` env var
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
