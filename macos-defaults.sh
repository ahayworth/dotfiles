#!/usr/bin/env bash
# macos-defaults.sh — replay the macOS `defaults` tweaks for a fresh machine.
#
# Run MANUALLY after a re-image (NOT auto-applied by chezmoi):
#   bash ~/projects/dotfiles/macos-defaults.sh
#
# The "Confirmed" block reflects what was actually non-default on this machine
# (captured 2026-06-29). The "Common extras" block is commented out — uncomment
# anything you want. For anything not here, see macos-defaults-snapshot.txt in the
# Drive backup (full `defaults read` dump) and the manual checklist in REIMAGE.md.
set -euo pipefail

echo "Applying macOS defaults…"

# ── Confirmed tweaks (were set on the old machine) ──
# Dock: auto-hide, smaller icons
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 46

# Trackpad: tap-to-click OFF (you require a physical click)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false

# ── Common extras (uncomment to enable; none were set on the old machine — pure suggestions) ──
# Faster key repeat + short delay (great for vim):
# defaults write NSGlobalDomain KeyRepeat -int 2
# defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Allow press-and-hold to repeat instead of showing accent menu:
# defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Full keyboard access (Tab through all controls in dialogs):
# defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
# Finder: show all extensions, path bar, status bar, POSIX path in title:
# defaults write com.apple.finder AppleShowAllExtensions -bool true
# defaults write com.apple.finder ShowPathbar -bool true
# defaults write com.apple.finder ShowStatusBar -bool true
# defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# Search the current folder by default (not whole Mac):
# defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Screenshots to ~/Screenshots as PNG, no window shadow:
# mkdir -p "$HOME/Screenshots"
# defaults write com.apple.screencapture location -string "$HOME/Screenshots"
# defaults write com.apple.screencapture type -string "png"
# defaults write com.apple.screencapture disable-shadow -bool true
# Don't write .DS_Store on network/USB volumes:
# defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Disable auto-capitalization / period substitution (often unwanted while coding):
# defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# ── Apply ──
for app in Dock Finder SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done
echo "Done. Some changes need a logout/login to fully take effect."
