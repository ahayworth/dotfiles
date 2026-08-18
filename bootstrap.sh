#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# devbox: mirror the detection in home/.chezmoi.toml.tmpl (filesystem
# markers + hostname; env vars aren't visible to every shell)
is_devbox() {
  [ -d /etc/workstation-startup.d ] || return 1
  [ -f "$HOME/agentd/workstation.env" ] && return 0
  [ -n "${AGENTD_HOME:-}" ] && return 0
  case "$(hostname)" in *devbox*) return 0 ;; esac
  return 1
}

if is_devbox; then
  # Run from the repo checkout: chezmoi hasn't deployed ~/.local/bin yet on
  # a fresh box.
  bash "$SCRIPT_DIR/home/dot_local/bin/executable_devbox-ensure-packages"
  export PATH="$PATH:$HOME/.local/bin"
fi

# Install chezmoi if not present
if ! command -v chezmoi >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install chezmoi
  else
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$PATH:$HOME/.local/bin"
  fi
fi

# Install Homebrew packages on macOS
if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
  if [ -f "$SCRIPT_DIR/Brewfile" ]; then
    brew bundle --file="$SCRIPT_DIR/Brewfile"
  fi
fi

# Initialize and apply chezmoi from this repo
chezmoi init --source="$SCRIPT_DIR" --apply
