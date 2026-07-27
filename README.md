# tmux config

Prefix is `C-s`.

## Layout

- `tmux.conf` — symlinked to `~/.tmux.conf`
- `scripts/` — custom scripts used by `tmux.conf`
- `plugins/` — TPM-managed plugins (git-ignored, see setup below)

Catppuccin (the status bar theme) is loaded from `~/.config/tmux/plugins/catppuccin`,
outside this repo, since it isn't TPM-managed here.

## Session switcher (`prefix + f`)

Opens a popup listing sessions (current one marked). While it's open:

- `enter` — switch to the selected session
- `n` — type a name and create a new session (switches into it)
- `r` `r` — kill the selected session (press `r` twice to confirm)
- `c` `r` — rename the selected session (type the new name after)
- `esc` — cancel the pending action, or close the popup

## Setup on a new machine

```sh
git clone git@github.com:IvanCCO/tmux.git ~/.tmux
~/.tmux/install.sh
```

Then open tmux and press `prefix + I` to install the TPM-managed plugins
declared in `tmux.conf`.
