# bootfire

[Docs site](https://btrainwilson.github.io/bootfire/) ·
[Integrations](https://btrainwilson.github.io/bootfire/docs/integrations)

Fuzzy-find a project directory, `cd` into it, and run its `start.sh`.

One keystroke from "where do I want to go" to "I'm in the project and it's
running." A small POSIX shell script around `fzf` and `fd`, plus a fish or
bash/zsh wrapper for the `cd`.

## Install

### curl | sh

```sh
curl -fsSL https://btrainwilson.github.io/bootfire/install.sh | sh
```

(The raw GitHub URL —
`https://raw.githubusercontent.com/btrainwilson/bootfire/main/install.sh`
— also works, and pins to a commit if you append `?ref=<sha>`.)

The installer:

- ensures `fzf` and `fd` are installed (via your package manager),
- clones bootfire to `~/.local/share/bootfire`,
- symlinks the `bootfire` binary into `~/.local/bin`,
- copies default config to `~/.config/bootfire/`,
- prints the `source` line to add to your shell rc.

### Manual

```sh
git clone https://github.com/btrainwilson/bootfire.git
cd bootfire
make install
```

You'll need `fzf` and `fd` installed yourself. On Debian/Ubuntu, `fd` is
packaged as `fd-find`; create an `fd` symlink (the `curl | sh` installer
does this automatically).

### Shell hook

Add **one** of these to your shell rc:

```fish
# ~/.config/fish/config.fish
source ~/.local/share/bootfire/shell/bootfire.fish
```

```sh
# ~/.bashrc or ~/.zshrc
source ~/.local/share/bootfire/shell/bootfire.sh
```

## Usage

```sh
bootfire add ~/code           # register a project root
bootfire add ~/work
bootfire                      # fuzzy-pick a directory; cd; run start.sh if present
bootfire -c                   # cd-only, skip start.sh
bootfire list                 # show configured roots
bootfire rm ~/work            # remove a root
bootfire --edit               # open the config in $EDITOR
```

Drop a `start.sh` in any project. It runs after `cd`. Put whatever boot
ritual you want inside it — start a dev server, open tmux windows, source
a venv. bootfire stays out of your way.

See **[Integrations](docs/integrations.md)** for working snippets:
tmux, zellij, Neovim/telescope, direnv, mise, and a per-language
`start.sh` template pattern.

## How ranking works

Candidates come from walking each configured root with `fd` (so each
repo's `.gitignore` is respected, plus the global ignore list at
`~/.config/bootfire/ignore`). Each candidate is scored by frecency:

```
score = count * w(age)
w(age) = 4.0  if age < 1h
       = 2.0  if age < 1d
       = 1.0  if age < 7d
       = 0.25 otherwise
```

Frecency only updates when bootfire itself selects a directory — there
are no shell hooks. New directories you've never picked start at score 0
and rank by alphabetical fall-through.

`fzf` reorders by match quality first; the frecency ranking acts as the
tiebreak (`--tiebreak=index`).

## Config

`~/.config/bootfire/config`:

```
root=~/code
root=~/work
max_depth=4
start_script=start.sh
```

`~/.config/bootfire/ignore` is a `.gitignore`-style file applied on top
of each repo's own `.gitignore`.

Frecency data lives at `~/.local/share/bootfire/frecency` (TSV:
`path<TAB>count<TAB>last_ts`).

## Uninstall

```sh
make uninstall
```

Or remove the symlink and install dir manually:

```sh
rm ~/.local/bin/bootfire
rm -rf ~/.local/share/bootfire
```

Config and frecency data are left in place. Remove `~/.config/bootfire`
and `~/.local/share/bootfire` if you want a full wipe.

## Tests

```sh
make test
```

Runs the frecency unit test and the end-to-end smoke test against an
isolated XDG home — won't touch your real config.

## Dependencies

- `fzf`
- `fd` (called as `fd`, not `fdfind` — the installer creates a shim on
  Debian/Ubuntu)
- POSIX `sh` for the core; `fish` 3+ or `bash` 4+ / `zsh` 5+ for the
  wrapper.
