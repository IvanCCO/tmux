#!/usr/bin/env bash
# Bootstraps everything this tmux config needs that isn't tracked in git:
# TPM itself (tmux.conf's declared @plugin list is installed via TPM,
# see README) and catppuccin, which is loaded from ~/.config/tmux and is
# not TPM-managed.
set -euo pipefail

if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "Cloning TPM..."
  git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [ ! -d ~/.config/tmux/plugins/catppuccin/tmux ]; then
  echo "Cloning catppuccin/tmux..."
  git clone --depth 1 https://github.com/catppuccin/tmux ~/.config/tmux/plugins/catppuccin/tmux
fi

if [ ! -e ~/.tmux.conf ]; then
  echo "Symlinking ~/.tmux.conf -> ~/.tmux/tmux.conf"
  ln -s ~/.tmux/tmux.conf ~/.tmux.conf
fi

echo "Done. Open tmux and press 'prefix + I' to install the remaining TPM plugins."
