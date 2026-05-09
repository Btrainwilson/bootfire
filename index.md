---
title: Home
nav_order: 1
permalink: /
---

# bootfire
{: .fs-9 }

Fuzzy-find a project directory, `cd` into it, and run its `start.sh`.
{: .fs-5 .fw-300 }

One keystroke from "where do I want to go" to "I'm in the project and
it's running." A small POSIX shell script around `fzf` and `fd`, plus a
fish or bash/zsh wrapper for the `cd`.

[Install](./install/){: .btn .btn-primary .mr-2 }
[View on GitHub](https://github.com/btrainwilson/bootfire){: .btn }

---

## Quick start

```sh
curl -fsSL https://btrainwilson.github.io/bootfire/install.sh | sh
```

Add the printed `source` line to your shell rc, open a new shell, then:

```sh
bootfire add ~/code      # register a project root
bootfire                 # fuzzy-pick → cd → run ./start.sh if present
```

That's the loop. Drop a `start.sh` in any project and bootfire runs it
on entry — anything else (tmux, dev servers, virtualenv activation)
lives inside that script.

## Where to go next

- **[Install](./install/)** — every install path, including manual and
  per-shell hooks.
- **[Usage](./usage/)** — every subcommand and flag, with examples.
- **[Config](./config/)** — config file format, ignore rules, paths.
- **[Integrations](./integrations/)** — tmux, Neovim/telescope, zellij,
  direnv, mise, per-language templates.
- **[How it works](./how-it-works/)** — the frecency math, the walker,
  why no shell hooks.
