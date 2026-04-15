# Neovim v0.12 Migration Plan: lazy.nvim → vim.pack + vanilla

## Goal

Strip the config down to be as vanilla as possible on Neovim 0.12. Replace
lazy.nvim with the built-in `vim.pack`, replace nvim-lspconfig with native
`vim.lsp.config()`/`vim.lsp.enable()`, remove plugins that v0.12 makes
redundant, and rewrite the treesitter setup for the new API.

---

## What changes for you as the user

### Plugin management

| Before (lazy.nvim)             | After (vim.pack)                        |
|--------------------------------|-----------------------------------------|
| `:Lazy` dashboard              | No dashboard — use `:PackUpdate` (TBD)  |
| `:Lazy update`                 | `vim.pack.update()` — opens a diff buffer you confirm |
| `:Lazy sync`                   | `vim.pack.update()` (install + update in one) |
| Auto-update checker in background | Gone — you run updates manually        |
| Lazy loading (`event`, `cmd`, `keys`, `ft`) | **None** — all plugins load at startup |
| `lazy-lock.json`               | `nvim-pack-lock.json` (auto-managed)    |

**Startup time impact:** You're going from ~25 plugins (many lazy-loaded) to
~17 plugins (all eager). With modern hardware this should still be fast
(sub-100ms), but you will notice if a plugin has expensive init. We can measure
with `nvim --startuptime /tmp/startup.log` before and after.

### Keybindings that change

| Binding          | Before                        | After (v0.12 default)        |
|------------------|-------------------------------|------------------------------|
| `grn`            | (unmapped)                    | `vim.lsp.buf.rename()`       |
| `gra`            | (unmapped)                    | `vim.lsp.buf.code_action()`  |
| `grr`            | (unmapped)                    | `vim.lsp.buf.references()`   |
| `gri`            | (unmapped)                    | `vim.lsp.buf.implementation()` |
| `grt`            | (unmapped)                    | `vim.lsp.buf.type_definition()` |
| `grx`            | (unmapped)                    | `vim.lsp.codelens.run()`     |
| `gO`             | (unmapped)                    | `vim.lsp.buf.document_symbol()` |
| `<C-S>` (insert) | (unmapped)                   | `vim.lsp.buf.signature_help()` |
| `v` then `an/in` | (unmapped)                   | Incremental treesitter node selection |
| `<leader>cr`     | `vim.lsp.buf.rename()`       | **Kept** (your custom map)   |
| `<leader>ca`     | `vim.lsp.buf.code_action()`  | **Kept** (your custom map)   |
| `gd`, `gr`, `gI`, `gy` | Snacks picker LSP     | **Kept** (your custom maps)  |

Your existing `<leader>c*` and Snacks picker LSP maps will coexist with the
new `gr*` defaults. No conflicts. You effectively get **two ways** to do
rename, code action, etc.

### Features you gain

- `vim.o.autocomplete = true` — completion popup shows as you type (optional)
- `vim.o.pumborder = 'rounded'` — bordered completion menu (no plugin needed)
- `:restart` — restart Neovim in-place, great for config iteration
- `:lsp` command — replaces `:LspInfo`, `:LspRestart`, `:LspLog`
- Incremental treesitter selection (`an`/`in`/`]n`/`[n` in visual mode)
- Built-in treesitter-aware commenting (replaces ts-comments.nvim)
- Default statusline with diagnostics + LSP progress (hidden by mini.statusline)

### Features you lose

- **Lazy loading** — all plugins load at startup
- **Auto update checker** — no background "X plugins have updates" notification
- **`:Lazy` UI** — the pretty dashboard with profiling, logs, etc.
- **hardtime.nvim** — no more movement restrictions (you wanted this)

### Plugins removed (4)

| Plugin                | Reason                                            |
|-----------------------|---------------------------------------------------|
| `m4xshen/hardtime.nvim` (+nui.nvim) | You want it gone                   |
| `vhyrro/luarocks.nvim`  | You want it gone                                |
| `folke/ts-comments.nvim` | v0.12 built-in treesitter commenting replaces it |
| `folke/lazy.nvim`        | Replaced by vim.pack                            |

### Plugins kept (17 + 2 dependencies)

which-key, treesitter (+textobjects, +context), todo-comments, vim-sleuth,
mini.nvim, oil.nvim (+mini.icons), harpoon (+plenary), conform, fidget,
nvim-lint, snacks, trouble, gitsigns, tokyonight, gruvbox, dark-notify.

> **Note on harpoon:** You said you rarely use it. It stays in the plan for
> now but is an easy cut later. Just say the word.

---

## New file structure

```
~/.config/nvim/
├── init.lua                          # Entry point (rewritten)
├── lua/
│   ├── options.lua                   # Options (minor v0.12 additions)
│   ├── keymaps.lua                   # Global keymaps (unchanged)
│   ├── commands.lua                  # User commands (unchanged)
│   ├── config/
│   │   ├── autocmds.lua              # Autocmds (minor cleanup)
│   │   └── pack.lua                  # NEW — replaces lazy.lua
│   └── plugins/                      # Plugin setup (require'd from init.lua)
│       ├── editor.lua                # which-key, treesitter, todo-comments, vim-sleuth, mini
│       ├── ui.lua                    # snacks, trouble, gitsigns
│       ├── lsp.lua                   # native LSP + LspAttach + fidget + nvim-lint
│       ├── formatting.lua            # conform
│       ├── filesystem.lua            # oil, (harpoon)
│       └── colorscheme.lua           # gruvbox, tokyonight, dark-notify
├── lsp/                              # NEW — native LSP server configs
│   ├── lua_ls.lua
│   ├── gopls.lua
│   ├── ts_ls.lua
│   ├── denols.lua
│   ├── yamlls.lua
│   ├── basedpyright.lua
│   └── ocamllsp.lua
```

### Files deleted

- `lua/config/lazy.lua` — replaced by `lua/config/pack.lua`
- `lazy-lock.json` — replaced by `nvim-pack-lock.json` (auto-generated)
- `lua/plugins/lang/javascript.lua` — ts-comments removed, nothing left
- `lua/plugins/lang/lua.lua` — luarocks removed, nothing left
- `lua/plugins/lang/` directory — empty after above

---

## Execution order

Each phase is a self-contained commit. If something breaks, we can bisect.

### Phase 0: Prerequisite

**Install the tree-sitter CLI** (needed for treesitter parser installation in v0.12):

```sh
brew install tree-sitter
```

You need to do this before we start.

---

### Phase 1: Remove plugins (safe, no dependencies)

Delete the 3 unwanted plugins and their config:

1. **Delete `lua/plugins/lang/lua.lua`** (luarocks.nvim)
2. **Delete `lua/plugins/lang/javascript.lua`** (ts-comments.nvim)
3. **Remove hardtime.nvim block** from `lua/plugins/editor.lua` (lines 171-178)
4. **Delete `lua/plugins/lang/` directory** (now empty)

**Test:** `:Lazy` should show fewer plugins. Everything else works as before.

---

### Phase 2: Replace nvim-lspconfig with native LSP

This is independent of the plugin manager migration and can be done while still
on lazy.nvim.

1. **Create `lsp/` directory** with one file per server:

   - `lsp/lua_ls.lua` — return `{ cmd, filetypes, root_markers, settings }`
   - `lsp/gopls.lua`
   - `lsp/ts_ls.lua` — includes `root_markers = { "tsconfig.json" }`,
     `single_file_support = false`, your import preferences
   - `lsp/denols.lua` — includes `root_markers = { "deno.json", "deno.jsonc" }`
   - `lsp/yamlls.lua` — includes your CFN schemas and custom tags
   - `lsp/basedpyright.lua` — includes your strict type checking settings
   - `lsp/ocamllsp.lua`

2. **Rewrite `lua/plugins/lsp.lua`:**
   - Remove the entire `nvim-lspconfig` plugin block
   - Add `vim.lsp.enable({ 'lua_ls', 'gopls', 'ts_ls', 'denols', 'yamlls', 'basedpyright', 'ocamllsp' })`
   - Keep the `LspAttach` autocmd as-is (it's already correct)
   - Keep fidget.nvim and nvim-lint blocks as-is

3. **Clean up `options.lua`:**
   - Remove `statuscolumn` line referencing `snacks.statuscolumn` (line 66) —
     this should be set by the snacks plugin config, not options

**What changes for you:** `:LspInfo` becomes `:lsp`. Server configs live in
individual `lsp/*.lua` files (easier to find and edit). Everything else is the
same.

**Test:** Open files in each language, confirm LSP attaches, completion works,
diagnostics appear, `<leader>cr` renames, `<leader>ca` shows actions.

---

### Phase 3: Rewrite treesitter config

The nvim-treesitter plugin's API completely changed. The `master` branch is
archived.

1. **Update the treesitter block in `lua/plugins/editor.lua`:**
   - Switch to `branch = "main"` (or the `neovim-treesitter/nvim-treesitter` fork)
   - Remove `require("nvim-treesitter.configs")` — module no longer exists
   - Remove `ensure_installed` table — use `require('nvim-treesitter').install(parsers)`
   - Remove `highlight = { enable = true }` — use `vim.treesitter.start()` via autocmd
   - Remove `indent = { enable = true }` — use `vim.bo.indentexpr` via autocmd
   - Keep textobjects config (rewrite for new API if needed)
   - Keep treesitter-context config

2. **Add a FileType autocmd** (in the treesitter config or in autocmds.lua):
   ```lua
   vim.api.nvim_create_autocmd('FileType', {
     callback = function()
       pcall(vim.treesitter.start)
     end,
   })
   ```

3. **Update textobjects + context** to `branch = "main"` as well.

**What changes for you:** Treesitter highlighting and indent work the same.
Parser installation happens programmatically instead of via `ensure_installed`.
You get the new `an`/`in`/`]n`/`[n` incremental selection for free.

**Test:** Open files in each language, confirm syntax highlighting works,
textobjects (`af`, `if`, `ac`, `ic`, `aa`, `ia`) work, motions (`]f`, `[f`,
`]c`, `[c`) work, context header appears.

---

### Phase 4: Migrate from lazy.nvim to vim.pack

This is the big one. We rewrite the plugin loading entirely.

1. **Create `lua/config/pack.lua`:**
   ```lua
   -- Declare all plugins
   vim.pack.add({
     'https://github.com/folke/which-key.nvim',
     'https://github.com/nvim-treesitter/nvim-treesitter',
     'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
     'https://github.com/nvim-treesitter/nvim-treesitter-context',
     'https://github.com/folke/todo-comments.nvim',
     'https://github.com/nvim-lua/plenary.nvim',
     'https://github.com/tpope/vim-sleuth',
     'https://github.com/echasnovski/mini.nvim',
     'https://github.com/echasnovski/mini.icons',
     'https://github.com/stevearc/oil.nvim',
     'https://github.com/ThePrimeagen/harpoon',
     'https://github.com/stevearc/conform.nvim',
     'https://github.com/j-hui/fidget.nvim',
     'https://github.com/mfussenegger/nvim-lint',
     'https://github.com/folke/snacks.nvim',
     'https://github.com/folke/trouble.nvim',
     'https://github.com/lewis6991/gitsigns.nvim',
     'https://github.com/folke/tokyonight.nvim',
     'https://github.com/ellisonleao/gruvbox.nvim',
     'https://github.com/cormacrelf/dark-notify',
   })
   ```

2. **Rewrite each `lua/plugins/*.lua` file** from lazy.nvim declarative format
   to imperative Lua:
   - Remove all lazy.nvim keys: `event`, `cmd`, `keys`, `lazy`, `priority`,
     `build`, `dependencies`, `version`, `opts`, `specs`
   - Replace `opts = { ... }` with `require("plugin").setup({ ... })`
   - Move `keys = { ... }` into `vim.keymap.set()` calls (either in the
     plugin file or in `keymaps.lua`)
   - Each file becomes a plain Lua module that configures its plugins

3. **Rewrite `init.lua`:**
   ```lua
   -- Leaders must be set before anything else
   vim.g.mapleader = " "
   vim.g.maplocalleader = "\\"

   -- Install/declare plugins
   require("config.pack")

   -- Core config
   require("options")
   require("config.autocmds")
   require("keymaps")
   require("commands")

   -- Plugin configs
   require("plugins.colorscheme")
   require("plugins.editor")
   require("plugins.ui")
   require("plugins.lsp")
   require("plugins.formatting")
   require("plugins.filesystem")
   ```

4. **Delete:**
   - `lua/config/lazy.lua`
   - `lazy-lock.json` (after confirming vim.pack works)

**What changes for you:**
- First launch after migration: `vim.pack.add()` will clone all plugins (one-time)
- No `:Lazy` command — use `vim.pack.update()` to update plugins
- Startup loads all plugins eagerly — expect roughly similar speed with 17 plugins
- Plugin config files look like normal Lua instead of lazy.nvim spec tables

**Test:** `nvim --startuptime /tmp/startup.log` — check startup time.
Open various filetypes, verify everything works: LSP, completion, formatting,
linting, picker, oil, treesitter, diagnostics, git signs, colorscheme
switching.

---

### Phase 5: v0.12 polish (optional improvements)

These are quality-of-life additions you can opt into:

1. **Add new v0.12 options to `options.lua`:**
   ```lua
   vim.o.pumborder = 'rounded'     -- bordered completion popup
   -- vim.o.autocomplete = true     -- uncomment if you want auto-popup completion
   ```

2. **Enable LSP completion autotrigger** (in LspAttach):
   ```lua
   vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
   ```
   Currently you have `autotrigger = false`. With v0.12's improved completion,
   you may want to try `true`.

3. **Clean up autocmds.lua:**
   - The `TextYankPost` highlight-on-yank may now be a default in v0.12 — verify
     and remove if redundant
   - The `close_with_q` autocmd references `"PlenaryTestPopup"`, `"lspinfo"`,
     `"tsplayground"` — these can be cleaned up

4. **Consider removing the `statuscolumn` snacks dependency** from options.lua
   (line 66) and moving it into the snacks plugin config where it belongs.

---

## Risk assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| vim.pack API differs from research | Medium | We verify against `:help vim.pack` on your v0.12 install before coding |
| Treesitter plugin rewrite has rough edges | Medium | We keep nvim-treesitter for parser management, only change config API |
| Startup slower without lazy loading | Low | 17 plugins is modest; measure with `--startuptime` |
| Some snacks features break without lazy.nvim's `VeryLazy` event | Low | Replace with `vim.api.nvim_create_autocmd("UIEnter", ...)` if needed |
| Harpoon/plenary breaks without lazy.nvim branch tracking | Low | Specify branch in vim.pack.add() |

---

## Verification checklist (run after each phase)

- [ ] Neovim starts without errors (`:messages`)
- [ ] Colorscheme loads correctly (gruvbox, dark/light switching)
- [ ] LSP attaches on: `.lua`, `.go`, `.ts`, `.tsx`, `.py`, `.yaml`, `.ml`
- [ ] Completion works (`<C-n>` or autotrigger)
- [ ] Formatting works (`<leader>cf`)
- [ ] Linting works (open a .ts file with eslint errors)
- [ ] Treesitter highlighting works
- [ ] Treesitter textobjects work (`daf`, `vic`, `]f`, `[c`)
- [ ] Treesitter context header appears
- [ ] Snacks picker works (`<leader>ff`, `<leader>/`, `<leader><space>`)
- [ ] Oil works (`<leader>of`)
- [ ] Which-key popup appears (press `<leader>` and wait)
- [ ] Trouble works (`<leader>xx`)
- [ ] Git signs appear in gutter
- [ ] Diagnostics display correctly
- [ ] Todo comments are highlighted
- [ ] `gc`/`gcc` commenting works (including in JSX/TSX)
- [ ] Folding works
