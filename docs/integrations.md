---
layout: default
title: Integrations
---

# Integrations

bootfire stays out of your way: it picks a directory, `cd`s, and runs
`./start.sh`. Everything else — tmux sessions, editor pickers, env
loading — is up to you. This page collects working snippets for the
most common combinations.

- [tmux](#tmux) — open or attach a session named after the project
- [zellij](#zellij) — same idea for zellij users
- [Neovim + telescope](#neovim--telescope) — fuzzy-pick from inside Neovim
- [Vim/Neovim built-in](#vimneovim-builtin) — no plugin required
- [direnv](#direnv) — auto-load project env on entry
- [mise / asdf](#mise--asdf) — auto-switch tool versions
- [Globally per-language](#globally-per-language) — share a default
  `start.sh` template across many projects

---

## tmux

Drop this into a project's `start.sh` to attach to (or create) a
session named after the project, with editor / shell / server windows:

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

If you launched bootfire from inside an existing tmux session, swap the
final `tmux attach` for `tmux switch-client -t "$SESSION"`. Detect with
`[ -n "${TMUX:-}" ]`.

---

## zellij

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

Pair with a layout file (`~/.config/zellij/layouts/dev.kdl`) that
opens the panes you want.

---

## Neovim + telescope

A custom telescope picker that lists bootfire candidates and `:cd`s on
selection. Drop this in `~/.config/nvim/lua/bootfire.lua`:

```lua
local pickers      = require('telescope.pickers')
local finders      = require('telescope.finders')
local actions      = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf         = require('telescope.config').values

local M = {}

function M.pick(opts)
  opts = opts or {}
  local handle = io.popen('BOOTFIRE_PRINT_CANDIDATES=1 bootfire-core 2>/dev/null')
  if not handle then
    vim.notify('bootfire-core not found', vim.log.levels.ERROR)
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
          os.execute('bootfire-core --bump ' .. vim.fn.shellescape(picked))
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

The picker uses `BOOTFIRE_PRINT_CANDIDATES=1` so the core prints its
ranked candidate list without invoking fzf — telescope handles fuzzy
matching.

---

## Vim/Neovim built-in

No plugin, no Lua. Works in vim and neovim:

```vim
command! Bootfire call s:bootfire()
function! s:bootfire() abort
  let l:dir = system('bootfire-core --filter='''' | head -n1')
  let l:dir = substitute(l:dir, '\n$', '', '')
  if !empty(l:dir)
    execute 'cd' fnameescape(l:dir)
    call system('bootfire-core --bump ' . shellescape(l:dir))
  endif
endfunction
```

Replace `--filter=""` with a prompt for a real query if you want
interactive matching.

---

## direnv

[direnv](https://direnv.net) auto-loads `.envrc` when you enter a
directory. Pairs naturally with bootfire — the `cd` triggers direnv,
then `start.sh` runs in the loaded environment:

```sh
# .envrc
export DATABASE_URL=postgres://localhost/myapp
export API_KEY=$(pass api/myapp)
PATH_add bin
```

Run `direnv allow` once per project. Inside `start.sh` you can rely on
those env vars being set.

---

## mise / asdf

[mise](https://mise.jdx.dev) (and asdf) auto-switch tool versions based
on a project file. Add a `.mise.toml`:

```toml
[tools]
node = "20"
python = "3.12"
```

When bootfire `cd`s in, mise activates the right versions before
`start.sh` runs. No code change needed — both tools key off the
directory entry hook in your shell.

---

## Globally per-language

Don't want to write `start.sh` in every project? Symlink a shared
template, then override per-project where needed:

```sh
ln -s ~/.config/bootfire/templates/node.sh   ~/code/myapp/start.sh
ln -s ~/.config/bootfire/templates/python.sh ~/code/datatools/start.sh
```

Or have a single per-language `start.sh` that detects the project type:

```sh
#!/bin/sh
if   [ -f package.json ];     then exec ~/.config/bootfire/templates/node.sh
elif [ -f pyproject.toml ];   then exec ~/.config/bootfire/templates/python.sh
elif [ -f Cargo.toml ];       then exec ~/.config/bootfire/templates/rust.sh
elif [ -f go.mod ];           then exec ~/.config/bootfire/templates/go.sh
fi
```

---

## Combining several

A common stack: tmux session per project, direnv for env, mise for tool
versions, telescope binding for in-editor jumps. None of them know
about bootfire — they just respond to `cd` and to a launched
`start.sh`. That's the point: bootfire is a thin coordinator, not an
ecosystem.
