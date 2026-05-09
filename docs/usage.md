---
title: Usage
nav_order: 3
permalink: /usage/
---

# Usage
{: .no_toc }

1. TOC
{:toc}

## Commands

| Command | What it does |
|---|---|
| `bootfire` | fuzzy-pick a directory, `cd` into it, run `./start.sh` if present |
| `bootfire -c`, `bootfire --cd-only` | same as above but skip `start.sh` |
| `bootfire add <path>` | register a project root in the config |
| `bootfire rm <path>` | remove a project root from the config |
| `bootfire list` | print configured roots |
| `bootfire --edit` | open the config in `$EDITOR` |
| `bootfire -h`, `bootfire --help` | show help |

## start.sh

Drop a `start.sh` in any project. It runs after `cd`. Put whatever
boot ritual you want inside it — start a dev server, open tmux
windows, source a venv. bootfire stays out of your way.

If a project has no `start.sh`, bootfire silently `cd`s and stops.

## A typical session

```sh
bootfire add ~/code            # one-time
bootfire add ~/work
bootfire                       # picker opens, type a few letters
                               # → cd into the match
                               # → source start.sh if present
```

Ranking is just `fzf` match quality on what you type — no usage
tracking. See [How it works](../how-it-works/) for the rest.

## See also

- [Config](../config/) — what the config file looks like and where
  data lives.
- [Integrations](../integrations/) — recipes for `start.sh`.
