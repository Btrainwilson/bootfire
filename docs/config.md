---
title: Config
nav_order: 4
permalink: /config/
---

# Config
{: .no_toc }

1. TOC
{:toc}

## Files

| File | Purpose |
|---|---|
| `~/.config/bootfire/config` | roots, max depth, start-script name |
| `~/.config/bootfire/ignore` | global `.gitignore`-style patterns |
| `~/.local/share/bootfire/frecency` | TSV: `path<TAB>count<TAB>last_ts` |

All three respect `$XDG_CONFIG_HOME` and `$XDG_DATA_HOME` if set.

## Main config

```
# ~/.config/bootfire/config
root=~/code
root=~/work
max_depth=4
start_script=start.sh
```

| Field | Meaning | Default |
|---|---|---|
| `root=` | a project-roots line; tildes expanded; can repeat | (none — at least one is required) |
| `max_depth` | how many levels to walk under each root | `4` |
| `start_script` | name of the script to run after `cd` | `start.sh` |

Use `bootfire add <path>` and `bootfire rm <path>` to manage roots
without editing the file by hand. `bootfire --edit` opens the file in
`$EDITOR`.

## Ignore file

```
# ~/.config/bootfire/ignore
.git/
node_modules/
.venv/
target/
dist/
build/
```

`.gitignore` syntax. Applied **on top of** each repo's own
`.gitignore` — `fd` already respects per-repo ignores natively, so the
global file is for noise that's the same everywhere (vendor dirs, OS
clutter, etc.).

## Frecency data

```
# ~/.local/share/bootfire/frecency
/home/you/code/bootfire    7    1730481234
/home/you/code/notes       2    1730390000
```

Tab-separated: absolute path, count, unix timestamp of last visit.
Updated only when bootfire itself selects a directory — there are no
shell hooks watching every `cd`. Safe to delete to reset rankings.
