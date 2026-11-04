#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
