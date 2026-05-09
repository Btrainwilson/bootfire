---
layout: default
title: bootfire
---

# bootfire

> Fuzzy-find a project directory, `cd` into it, and run its `start.sh`.

One keystroke from "where do I want to go" to "I'm in the project and it's
running."

## Install

```sh
curl -fsSL https://btrainwilson.github.io/bootfire/install.sh | sh
```

The installer ensures `fzf` and `fd` are present, clones the repo into
`~/.local/share/bootfire`, copies default config, and prints the line to
add to your shell rc.

## At a glance

```sh
bootfire add ~/code      # register a project root
bootfire                 # fuzzy-pick → cd → run ./start.sh
bootfire -c              # cd-only, skip start.sh
bootfire list            # show roots
bootfire --edit          # open config in $EDITOR
```

## Where to go next

- **[Integrations](./docs/integrations)** — tmux, Neovim/telescope, zellij,
  direnv, mise, and other ways to wire bootfire into your workflow.
- **[README](https://github.com/btrainwilson/bootfire#readme)** — full
  documentation, configuration, dependencies.
- **[Source](https://github.com/btrainwilson/bootfire)** — GitHub repo.

## How it works (in two paragraphs)

`bootfire-core` is a POSIX shell script that walks each configured root
with `fd` (so each repo's `.gitignore` is respected, plus a global ignore
file at `~/.config/bootfire/ignore`), scores candidates by frecency, and
hands the ranked list to `fzf`. It prints the selected path and exits.

A small fish or bash/zsh function wraps the core so it can `cd` your
shell into the chosen path and execute `./start.sh` if present. Tmux
windows, dev servers, virtualenv activation — anything you want to
happen on entry — goes inside the project's own `start.sh`. bootfire
never knows or cares about the contents.
