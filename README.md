# bootfire

[![License: MIT](https://img.shields.io/badge/license-MIT-8b2a0e?style=flat-square)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-pages-d4a017?style=flat-square)](https://btrainwilson.github.io/bootfire/)
[![POSIX sh](https://img.shields.io/badge/posix-sh-d2691e?style=flat-square)](#)
[![Shells](https://img.shields.io/badge/shells-fish%20%7C%20bash%20%7C%20zsh-a0522d?style=flat-square)](#)

_Fuzzy-find a project directory, `cd` into it, and run its `start.sh`._

> [!TIP]
> Full documentation lives at <https://btrainwilson.github.io/bootfire/> — this README is the short version.

---

## Install

```sh
curl -fsSL https://btrainwilson.github.io/bootfire/install.sh | sh
```

The installer ensures `fzf` and `fd` are installed, clones bootfire to
`~/.local/share/bootfire`, symlinks the `bootfire` binary into
`~/.local/bin`, copies default config to `~/.config/bootfire/`, and
prints the `source` line to add to your shell rc.

Then add **one** of these to your shell rc:

```fish
# ~/.config/fish/config.fish
source ~/.local/share/bootfire/shell/bootfire.fish
```

```sh
# ~/.bashrc or ~/.zshrc
source ~/.local/share/bootfire/shell/bootfire.sh
```

<details><summary>Manual install</summary>

```sh
git clone https://github.com/btrainwilson/bootfire.git
cd bootfire
make install
```

You'll need `fzf` and `fd` yourself. On Debian/Ubuntu, `fd` is packaged
as `fd-find` — symlink it as `fd` (the `curl | sh` installer does this
automatically).
</details>

---

## Usage

| Command | What it does |
|---|---|
| `bootfire` | fuzzy-pick → `cd` → source `./start.sh` if present |
| `bootfire -c` | `cd`-only, skip `start.sh` |
| `bootfire add <path>` | register a project root |
| `bootfire rm <path>` | remove a project root |
| `bootfire list` | print configured roots |
| `bootfire --edit` | open the config in `$EDITOR` |

Drop a `start.sh` in any project. It's **sourced** after `cd`, so any
env changes (venv activation, exported vars, deeper `cd`s) persist in
your shell. Whatever boot ritual you want — dev server, tmux windows,
virtualenv — goes inside that script. bootfire stays out of your way.

> [!NOTE]
> Because `start.sh` is sourced, it must be syntactically valid in
> your shell. Bash/zsh source POSIX `sh` fine; **fish** users need a
> fish-syntax `start.sh`.

> [!NOTE]
> See **[Integrations](https://btrainwilson.github.io/bootfire/integrations/)** for working `start.sh` snippets:
> tmux, zellij, Neovim/telescope, direnv, mise, and a per-language
> template pattern.

---

## How ranking works

There is no ranking. Candidates come from walking each configured
root with `fd` (so each repo's `.gitignore` is respected, plus the
global ignore at `~/.config/bootfire/ignore`), and `fzf` orders them
by match quality against what you type. No usage tracking, no shell
hooks.

Full rationale: [How it works](https://btrainwilson.github.io/bootfire/how-it-works/).

---

## Config

`~/.config/bootfire/config`:

```
root=~
max_depth=4
start_script=start.sh
```

`~/.config/bootfire/ignore` is `.gitignore`-style; layered on top of
each repo's own `.gitignore`.

---

<details><summary>Dependencies</summary>

| Tool | Purpose |
|---|---|
| `fzf` | the fuzzy picker |
| `fd` | the directory walker (called as `fd`, not `fdfind`) |
| POSIX `sh` | the core script |
| `fish` 3+ / `bash` 4+ / `zsh` 5+ | for the wrapper |

</details>

<details><summary>Tests</summary>

```sh
make test
```

Runs the end-to-end smoke test against an isolated XDG home — won't
touch your real config.
</details>

<details><summary>Uninstall</summary>

```sh
make uninstall
```

Or remove manually:

```sh
rm ~/.local/bin/bootfire
rm -rf ~/.local/share/bootfire
```

Config is left in place. Remove `~/.config/bootfire` for a full wipe.
</details>

---

MIT licensed. See [LICENSE](LICENSE).
