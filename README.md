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
| `bootfire` | fuzzy-pick → `cd` → run `./start.sh` if present |
| `bootfire -c` | `cd`-only, skip `start.sh` |
| `bootfire add <path>` | register a project root |
| `bootfire rm <path>` | remove a project root |
| `bootfire list` | print configured roots |
| `bootfire --edit` | open the config in `$EDITOR` |

Drop a `start.sh` in any project. It runs after `cd`. Whatever boot
ritual you want — dev server, tmux windows, virtualenv — goes inside
that script. bootfire stays out of your way.

> [!NOTE]
> See **[Integrations](https://btrainwilson.github.io/bootfire/integrations/)** for working `start.sh` snippets:
> tmux, zellij, Neovim/telescope, direnv, mise, and a per-language
> template pattern.

---

## How ranking works

Candidates come from walking each configured root with `fd` (so each
repo's `.gitignore` is respected, plus the global ignore at
`~/.config/bootfire/ignore`). Each candidate is scored by frecency:

| Age of last visit | Weight |
|---|---|
| < 1 hour | 4.0 |
| < 1 day  | 2.0 |
| < 7 days | 1.0 |
| ≥ 7 days | 0.25 |

Score is `count * weight`. Frecency updates **only** when bootfire
itself selects a directory — no shell hooks. New directories start at
score 0 and rank by alphabetical fall-through. `fzf` orders by match
quality first; frecency breaks ties (`--tiebreak=index`).

Full rationale: [How it works](https://btrainwilson.github.io/bootfire/how-it-works/).

---

## Config

`~/.config/bootfire/config`:

```
root=~/code
root=~/work
max_depth=4
start_script=start.sh
```

`~/.config/bootfire/ignore` is `.gitignore`-style; layered on top of
each repo's own `.gitignore`. Frecency data lives at
`~/.local/share/bootfire/frecency` (TSV: `path<TAB>count<TAB>last_ts`).

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

Runs the frecency unit test and the end-to-end smoke test against an
isolated XDG home — won't touch your real config.
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

Config and frecency data are left in place. Remove
`~/.config/bootfire` and `~/.local/share/bootfire` for a full wipe.
</details>

---

MIT licensed. See [LICENSE](LICENSE).
