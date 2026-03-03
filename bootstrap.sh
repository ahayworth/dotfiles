#!/bin/bash
set -euo pipefail

# Install chezmoi if not present
if ! command -v chezmoi >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install chezmoi
  else
    sh -c "$(curl -fsLS get.chezmoi.io)"
  fi
fi

# Install Homebrew packages on macOS
if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$SCRIPT_DIR/Brewfile" ]; then
    brew bundle --file="$SCRIPT_DIR/Brewfile"
  fi
fi

# Install starship in Codespaces
if [ "${CODESPACES:-}" = "true" ]; then
  if ! command -v starship >/dev/null 2>&1; then
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
  fi
fi

# Initialize and apply chezmoi from this repo
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chezmoi init --source="$SCRIPT_DIR" --apply
