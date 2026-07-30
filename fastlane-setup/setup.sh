#!/usr/bin/env bash
# Reproducible install of fastlane (https://github.com/fastlane/fastlane)
# as a Ruby gem, with rbenv-aware PATH handling and UTF-8 locale setup.
set -euo pipefail

# 1. Install the gem (85 gems total; --no-document keeps it fast).
sudo gem install fastlane --no-document

# 2. If Ruby is managed by rbenv, refresh shims and expose the versioned
#    binstub globally — its shebang pins the right Ruby, so it works even
#    when the shell's default ruby is a different install.
if [ -d /opt/rbenv ]; then
  sudo env RBENV_ROOT=/opt/rbenv /opt/rbenv/bin/rbenv rehash || true
  BINSTUB=$(ls /opt/rbenv/versions/*/bin/fastlane 2>/dev/null | sort -V | tail -1)
  if [ -n "$BINSTUB" ]; then
    sudo ln -sf "$BINSTUB" /usr/local/bin/fastlane
  fi
fi

# 3. fastlane requires a UTF-8 locale; persist one if none is set.
if ! grep -q "LC_ALL" "$HOME/.bashrc" 2>/dev/null; then
  printf '\nexport LC_ALL=C.UTF-8\nexport LANG=C.UTF-8\n' >> "$HOME/.bashrc"
fi
export LC_ALL=C.UTF-8 LANG=C.UTF-8

# 4. Verify.
fastlane --version
