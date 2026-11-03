#!/bin/bash
# Atticus (Fiven edition) installer. Paste in Terminal:
#   curl -fsSL https://raw.githubusercontent.com/BattleFiven/atticus-mac/fiven/meetings/install.sh | bash
# Gets the source to ~/.atticus (Atticus updates itself from there), installs Homebrew and whisper.cpp for
# on-device speech, builds the app and opens it. The first launch downloads the speech model by itself.
set -e
DIR="${ATTICUS_DIR:-$HOME/.atticus}"
REPO="${ATTICUS_REPO:-https://github.com/BattleFiven/atticus-mac.git}"
BRANCH="${ATTICUS_BRANCH:-fiven/meetings}"
echo "Installing Atticus…"
[ "$(sw_vers -productVersion | cut -d. -f1)" -ge 26 ] || { echo "Atticus needs macOS 26 or later."; exit 1; }
if ! xcode-select -p >/dev/null 2>&1; then
  echo "First, Apple's command line tools. A macOS window will open: click Install."
  echo "When it finishes, paste the install line again."
  xcode-select --install 2>/dev/null || true
  exit 1
fi
# A newly updated Xcode blocks every developer tool, python3 included, until its license is accepted.
if ! /usr/bin/python3 -c '' 2>/dev/null && xcodebuild -license check 2>&1 | grep -qi license; then
  echo "Xcode was updated and needs its license accepted (your Mac password is asked)."
  sudo xcodebuild -license accept </dev/tty
fi
BREW=$(command -v brew || ls /opt/homebrew/bin/brew /usr/local/bin/brew 2>/dev/null | head -1 || true)
if [ -z "$BREW" ]; then
  echo "Installing Homebrew, for on-device Whisper speech recognition (your Mac password is asked)…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
  BREW=$(ls /opt/homebrew/bin/brew /usr/local/bin/brew 2>/dev/null | head -1)
fi
if [ -n "$BREW" ] && ! "$BREW" list whisper.cpp >/dev/null 2>&1; then
  echo "Installing whisper.cpp…"
  NONINTERACTIVE=1 "$BREW" install whisper.cpp || echo "whisper.cpp didn't install; Atticus uses Apple's speech until it is."
fi
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" pull -q --ff-only || { echo "Could not update $DIR. Delete that folder, then paste the install line again."; exit 1; }
else
  git clone -q --depth 1 -b "$BRANCH" "$REPO" "$DIR"
fi
"$DIR/build.sh"
open "$HOME/Applications/Atticus.app"
echo "Done. The Atticus setup window walks you through the rest."
