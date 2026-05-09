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

Both respect `$XDG_CONFIG_HOME` if set.

## Main config

```
# ~/.config/bootfire/config
root=~
max_depth=4
start_script=start.sh
```

| Field | Meaning | Default |
|---|---|---|
| `root=` | a project-roots line; tildes expanded; can repeat | (none — at least one is required) |
| `max_depth` | how many levels to walk under each root | `4` |
| `start_script` | name of the script to source after `cd` | `start.sh` |

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
