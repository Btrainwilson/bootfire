---
title: How it works
nav_order: 6
permalink: /how-it-works/
---

# How it works
{: .no_toc }

1. TOC
{:toc}

## Two pieces

The `bootfire` binary is a POSIX shell script that walks each
configured root with `fd` (so each repo's `.gitignore` is respected,
plus the global ignore at `~/.config/bootfire/ignore`), dedups, and
hands the candidate list to `fzf`. It prints the selected path and
exits.

A small fish or bash/zsh function wraps the binary so it can `cd` your
shell into the chosen path and `source ./start.sh` if present. Tmux
windows, dev servers, virtualenv activation — anything you want to
happen on entry — goes inside the project's own `start.sh`. bootfire
never knows or cares about the contents.

## Why a shell function

A standalone binary can't change the working directory of the shell
that invoked it; the OS isolates child processes. The function lives
inside your shell, so it can `cd`, and it sources `start.sh` so any
env changes (venv activation, exported vars, deeper `cd`s) persist in
the calling shell rather than dying with a subshell.

## Ranking

There is none. `fzf` orders candidates by match quality against your
query — that's the whole story. No frecency, no usage tracking, no
shell hooks observing your `cd`s. New directories and old ones are on
equal footing; what you type is what ranks them.

## Shell compatibility for start.sh

Because the wrapper sources `start.sh` rather than executing it, the
script must be syntactically valid in the calling shell. Bash and zsh
both run POSIX `sh`-style scripts via `.`, so most `start.sh` files
work unchanged. **For fish users:** `start.sh` must be fish syntax —
`source` in fish only accepts fish.
