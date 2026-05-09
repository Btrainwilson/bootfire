---
title: Install
nav_order: 2
permalink: /install/
---

# Install
{: .no_toc }

1. TOC
{:toc}

## curl | sh

```sh
curl -fsSL https://btrainwilson.github.io/bootfire/install.sh | sh
```

The installer:

- ensures `fzf` and `fd` are installed (via your package manager),
- clones bootfire to `~/.local/share/bootfire`,
- symlinks the `bootfire` binary into `~/.local/bin`,
- copies default config to `~/.config/bootfire/`,
- prints the `source` line to add to your shell rc.

The raw GitHub URL also works and lets you pin to a commit:

```sh
curl -fsSL https://raw.githubusercontent.com/btrainwilson/bootfire/main/install.sh | sh
```

## Manual

```sh
git clone https://github.com/btrainwilson/bootfire.git
cd bootfire
make install
```

You'll need `fzf` and `fd` installed yourself. On Debian/Ubuntu, `fd`
is packaged as `fd-find` — create an `fd` symlink (the `curl | sh`
installer does this automatically).

## Shell hook

Add **one** of these to your shell rc:

```fish
# ~/.config/fish/config.fish
source ~/.local/share/bootfire/shell/bootfire.fish
```

```sh
# ~/.bashrc or ~/.zshrc
source ~/.local/share/bootfire/shell/bootfire.sh
```

The hook is what makes `bootfire` a shell function — needed because a
standalone binary can't `cd` your shell from the outside.

## Dependencies

| Tool | Purpose |
|---|---|
| `fzf` | the fuzzy picker |
| `fd` | the directory walker (respects `.gitignore`) |
| POSIX `sh` | the core script |
| `fish` 3+ / `bash` 4+ / `zsh` 5+ | for the wrapper |

## Uninstall

```sh
make uninstall
```

Or remove the install manually:

```sh
rm ~/.local/bin/bootfire
rm -rf ~/.local/share/bootfire
```

Config and frecency data are left in place. Remove them too if you
want a full wipe:

```sh
rm -rf ~/.config/bootfire ~/.local/share/bootfire
```
