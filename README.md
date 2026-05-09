# bootfire

[![License: MIT](https://img.shields.io/badge/license-MIT-8b2a0e?style=flat-square)](LICENSE)
[![POSIX sh](https://img.shields.io/badge/posix-sh-d2691e?style=flat-square)](#)
[![Shells](https://img.shields.io/badge/shells-fish%20%7C%20bash%20%7C%20zsh-a0522d?style=flat-square)](#)

_Fuzzy-find a project directory, `cd` into it, and source its `start.sh`._

---

## Install

```sh
curl -fsSL https://btrainwilson.github.io/bootfire/install.sh | sh
```

The installer ensures `fzf` and `fd` are present, clones bootfire to
`~/.local/share/bootfire`, symlinks the binary into `~/.local/bin`,
copies the default config to `~/.config/bootfire/`, and wires the
shell hook (detected from `$SHELL`):

- **fish** → drops `~/.config/fish/conf.d/bootfire.fish` (auto-sourced
  by fish; no rc edits)
- **bash / zsh** → writes a sentinel-marked block in `~/.bashrc` /
  `~/.zshrc`. Reinstalls *replace* the block instead of stacking
  duplicate lines

Set `BOOTFIRE_NO_SHELL_HOOK=1` to skip the hook. The hook is what
makes `bootfire` a shell function — needed because a standalone
binary can't `cd` your shell from the outside.

<details><summary>Manual install</summary>

```sh
git clone https://github.com/btrainwilson/bootfire.git
cd bootfire
make install
```

You'll need `fzf` and `fd` yourself. On Debian/Ubuntu, `fd` is
packaged as `fd-find` — symlink it as `fd`. `make install` does not
wire the shell hook; do one of:

```fish
# fish
mkdir -p ~/.config/fish/conf.d
echo 'source ~/.local/share/bootfire/shell/bootfire.fish' \
    > ~/.config/fish/conf.d/bootfire.fish
```

```sh
# ~/.bashrc or ~/.zshrc
source ~/.local/share/bootfire/shell/bootfire.sh
```

</details>

---

## Usage

| Command | What it does |
|---|---|
| `bootfire` | fuzzy-pick → `cd` → source `./start.sh` if present |
| `bootfire -c`, `--cd-only` | `cd`-only, skip `start.sh` |
| `bootfire add <path>` | register a project root |
| `bootfire rm <path>` | remove a project root |
| `bootfire list` | print configured roots |
| `bootfire --edit` | open the config in `$EDITOR` |
| `bootfire -h`, `--help` | show help |

Drop a `start.sh` in any project. It's **sourced** after `cd`, so any
env changes (venv activation, exported vars, deeper `cd`s) persist in
your shell.

> Because `start.sh` is sourced, it must be syntactically valid in
> your shell. Bash/zsh source POSIX `sh` fine; **fish** users need a
> fish-syntax `start.sh`.

---

## Config

`~/.config/bootfire/config`:

```
root=~
max_depth=4
start_script=start.sh
editor=
```

| Field | Meaning | Default |
|---|---|---|
| `root=` | a project-roots line; tildes expanded; can repeat | (at least one is required) |
| `max_depth` | how many levels to walk under each root | `4` |
| `start_script` | name of the script to source after `cd` | `start.sh` |
| `editor` | command for `bootfire --edit`; word-split, so flags work (e.g. `code --wait`) | `$EDITOR`, then `vi` |

Use `bootfire add <path>` and `bootfire rm <path>` to manage roots
without editing the file by hand. `bootfire --edit` opens it in
`$EDITOR`.

`~/.config/bootfire/ignore` is `.gitignore`-style; layered on top of
each repo's own `.gitignore`. Use it for noise that's the same
everywhere (vendor dirs, OS clutter):

```
.git/
node_modules/
.venv/
target/
dist/
build/
```

---

## Ranking

There is none. Candidates come from walking each configured root with
`fd` (so each repo's `.gitignore` is respected, plus the global
ignore). `fzf` orders them by match quality against what you type. No
usage tracking, no shell hooks, no frecency.

---

## How it works

The `bootfire` binary is a POSIX shell script that walks each
configured root with `fd`, dedups, and hands the candidate list to
`fzf`. It prints the selected path and exits — it never `cd`s.

A small fish or bash/zsh function wraps the binary so it can `cd` your
shell into the chosen path and `source ./start.sh` if present. The
function lives inside your shell, so its `cd` (and any `cd`/env
changes from `start.sh`) actually persist — a child process can't do
that to its parent.

---

## Integrations

`start.sh` snippets and recipes for common stacks. None of these
tools know about bootfire — they just respond to `cd` and to whatever
`start.sh` does.

### tmux

Attach to (or create) a session named after the project:

```sh
#!/bin/sh
set -eu
SESSION="$(basename "$PWD" | tr -c '[:alnum:]_' '-')"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach -t "$SESSION"
    exit 0
fi

tmux new-session -d -s "$SESSION" -c "$PWD" -n editor
tmux send-keys -t "$SESSION:editor" 'nvim .' Enter
tmux new-window  -t "$SESSION" -c "$PWD" -n shell
tmux new-window  -t "$SESSION" -c "$PWD" -n server
tmux send-keys   -t "$SESSION:server" 'npm run dev' Enter

tmux attach -t "$SESSION"
```

If you launched bootfire from inside an existing tmux session, swap
the final `tmux attach` for `tmux switch-client -t "$SESSION"`.
Detect with `[ -n "${TMUX:-}" ]`.

### zellij

```sh
#!/bin/sh
set -eu
SESSION="$(basename "$PWD")"

if zellij list-sessions 2>/dev/null | grep -qx "$SESSION"; then
    zellij attach "$SESSION"
else
    zellij --session "$SESSION" --layout ~/.config/zellij/layouts/dev.kdl
fi
```

### Neovim + telescope

A custom telescope picker. Drop in `~/.config/nvim/lua/bootfire.lua`:

```lua
local pickers      = require('telescope.pickers')
local finders      = require('telescope.finders')
local actions      = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf         = require('telescope.config').values

local M = {}

function M.pick(opts)
  opts = opts or {}
  local handle = io.popen('BOOTFIRE_PRINT_CANDIDATES=1 bootfire 2>/dev/null')
  if not handle then
    vim.notify('bootfire not found', vim.log.levels.ERROR)
    return
  end
  local lines = {}
  for line in handle:lines() do table.insert(lines, line) end
  handle:close()

  pickers.new(opts, {
    prompt_title = 'bootfire',
    finder = finders.new_table { results = lines },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local picked = action_state.get_selected_entry()[1]
        if picked then
          vim.cmd('cd ' .. vim.fn.fnameescape(picked))
        end
      end)
      return true
    end,
  }):find()
end

return M
```

Bind it:

```lua
vim.keymap.set('n', '<leader>fp', function()
  require('bootfire').pick()
end, { desc = 'bootfire pick' })
```

`BOOTFIRE_PRINT_CANDIDATES=1` makes the core print its candidate list
without invoking fzf — telescope handles fuzzy matching.

### Vim/Neovim built-in

No plugin, no Lua:

```vim
command! Bootfire call s:bootfire()
function! s:bootfire() abort
  let l:dir = system('bootfire --filter='''' | head -n1')
  let l:dir = substitute(l:dir, '\n$', '', '')
  if !empty(l:dir)
    execute 'cd' fnameescape(l:dir)
  endif
endfunction
```

### direnv

[direnv](https://direnv.net) auto-loads `.envrc` on `cd`. The
`bootfire`-driven `cd` triggers direnv, then `start.sh` runs in the
loaded environment:

```sh
# .envrc
export DATABASE_URL=postgres://localhost/myapp
export API_KEY=$(pass api/myapp)
PATH_add bin
```

`direnv allow` once per project.

### mise / asdf

[mise](https://mise.jdx.dev) (and asdf) auto-switch tool versions
based on a project file. Add `.mise.toml`:

```toml
[tools]
node = "20"
python = "3.12"
```

When bootfire `cd`s in, mise activates the right versions before
`start.sh` runs.

### Globally per-language

Symlink a shared template per project:

```sh
ln -s ~/.config/bootfire/templates/node.sh   ~/code/myapp/start.sh
ln -s ~/.config/bootfire/templates/python.sh ~/code/datatools/start.sh
```

Or one `start.sh` that detects the project type:

```sh
#!/bin/sh
if   [ -f package.json ];     then exec ~/.config/bootfire/templates/node.sh
elif [ -f pyproject.toml ];   then exec ~/.config/bootfire/templates/python.sh
elif [ -f Cargo.toml ];       then exec ~/.config/bootfire/templates/rust.sh
elif [ -f go.mod ];           then exec ~/.config/bootfire/templates/go.sh
fi
```

---

## Dependencies

| Tool | Purpose |
|---|---|
| `fzf` | the fuzzy picker |
| `fd` | the directory walker (called as `fd`, not `fdfind`) |
| POSIX `sh` | the core script |
| `fish` 3+ / `bash` 4+ / `zsh` 5+ | for the wrapper |

---

## Tests

```sh
make test
```

End-to-end smoke test against an isolated XDG home — won't touch your
real config.

---

## Uninstall

```sh
make uninstall
```

Or manually:

```sh
rm ~/.local/bin/bootfire
rm -rf ~/.local/share/bootfire
rm -f ~/.config/fish/conf.d/bootfire.fish    # if you used fish
# bash/zsh: remove the '# >>> bootfire >>>' block from your rc
```

Config is left in place. Remove `~/.config/bootfire` for a full wipe.

---

MIT licensed. See [LICENSE](LICENSE).
