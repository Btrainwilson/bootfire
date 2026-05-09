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
plus the global ignore at `~/.config/bootfire/ignore`), scores the
candidates by frecency, and hands the ranked list to `fzf`. It prints
the selected path and exits.

A small fish or bash/zsh function wraps the binary so it can `cd` your
shell into the chosen path and execute `./start.sh` if present. Tmux
windows, dev servers, virtualenv activation — anything you want to
happen on entry — goes inside the project's own `start.sh`. bootfire
never knows or cares about the contents.

## Why a shell function

A standalone binary can't change the working directory of the shell
that invoked it; the OS isolates child processes. The function lives
inside your shell, so it can `cd`. The binary on `$PATH` is what the
function (and editor integrations) shell out to for the picker.

## Frecency

Each candidate is scored:

```
score = count * w(age)
```

where `w(age)` is a step function on the time since you last picked
the directory:

| Age of last visit | Weight |
|---|---|
| < 1 hour | 4.0 |
| < 1 day  | 2.0 |
| < 7 days | 1.0 |
| ≥ 7 days | 0.25 |

Candidates that have never been picked score `0` and rank by the order
`fd` returned them — alphabetical fall-through.

Frecency only updates when bootfire itself selects a directory. There
are no shell hooks observing every `cd` — that's a deliberate
non-feature.

## Why fzf with `--tiebreak=index`

`fzf` reorders by match quality (how well your query string fits the
candidate). Frecency only kicks in to break ties. This means typing
`api` will surface `~/code/api-server` even if you've never picked it
— but among equally-good matches, the one you visit most often wins.

`--tiebreak=index` tells fzf to use the input order as the secondary
sort key, and we hand fzf a list pre-sorted by frecency descending.
Result: best fzf match first, frecency second.

## Why no shell hooks

Tools that hook into every `cd` (zoxide, autojump) need the user to
install the hook. They also pollute the frecency store with every
casual `cd` you make — including stops that aren't projects. bootfire
opts out: only directories you deliberately pick get scored. The
tradeoff is that frecency starts cold for new directories and warms up
slower. We think it's worth it for the simpler mental model.
